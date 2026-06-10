import Alamofire
import Combine
import Foundation
import SwiftyJSON

final class Networking {
    static let shared = Networking()

    private var headers: HTTPHeaders!

    private let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        return Session(configuration: configuration)
    }()

    private init() {}

    func header(bearerToken: String? = nil) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let token = bearerToken ?? UserManager.persistedToken ?? ""
        headers = [
            .authorization("Bearer \(token)"),
            .accept("application/json"),
            .contentType("application/json"),
            HTTPHeader(name: "X-App-Platform", value: "ios")
        ]
        if let appVersion {
            headers.add(HTTPHeader(name: "X-App-Version", value: appVersion))
        }
    }

    func requestPublisher(
        method: HTTPMethod,
        url: String,
        parameters: [String: Any] = [:],
        bearerToken: String? = nil
    ) -> AnyPublisher<JSON, ServiceError> {
        header(bearerToken: bearerToken)

        guard NetworkReachabilityManager()?.isReachable == true else {
            return Fail(error: ServiceError.customError("İnternet bağlantısı yok."))
                .eraseToAnyPublisher()
        }

        let encoding: ParameterEncoding = method == .get ? URLEncoding.queryString : JSONEncoding.default

        return session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .validate(statusCode: 200..<501)
            .publishData()
            .tryMap { response in
                try Self.mapResponse(data: response.data, httpResponse: response.response)
            }
            .mapError { error in
                if let serviceError = error as? ServiceError {
                    return serviceError
                }
                return ServiceError.customError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    func requestWithHTTPResponse(
        method: HTTPMethod,
        url: String,
        parameters: [String: Any] = [:],
        bearerToken: String? = nil
    ) async throws -> (json: JSON, response: HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            header(bearerToken: bearerToken)

            guard NetworkReachabilityManager()?.isReachable == true else {
                continuation.resume(throwing: ServiceError.customError("İnternet bağlantısı yok."))
                return
            }

            let encoding: ParameterEncoding = method == .get ? URLEncoding.queryString : JSONEncoding.default
            session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                .validate(statusCode: 200..<501)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let json = try Self.mapResponse(data: data, httpResponse: response.response)
                            guard let httpResponse = response.response else {
                                throw ServiceError.customError("Sunucudan geçersiz yanıt alındı.")
                            }
                            continuation.resume(returning: (json, httpResponse))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: ServiceError.customError(error.localizedDescription))
                    }
                }
        }
    }

    func request(
        method: HTTPMethod,
        url: String,
        parameters: [String: Any] = [:],
        bearerToken: String? = nil
    ) async throws -> JSON {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = requestPublisher(method: method, url: url, parameters: parameters, bearerToken: bearerToken)
                .sink { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { json in
                    continuation.resume(returning: json)
                    cancellable?.cancel()
                }
        }
    }

    private static func mapResponse(data: Data?, httpResponse: HTTPURLResponse?) throws -> JSON {
        guard let data, let httpResponse else {
            throw ServiceError.customError("Sunucudan geçersiz yanıt alındı.")
        }

        if httpResponse.statusCode == 404 {
            throw ServiceError.httpStatus(404)
        }

        let json = JSON(data)
        let metaCode = json["meta"]["code"].intValue
        if metaCode == StateCode.success.rawValue {
            return json
        }

        let message = json["meta"]["message"].stringValue
        let fallback = message.isEmpty ? "Bir hata oluştu." : message
        if metaCode == StateCode.informational.rawValue {
            throw ServiceError.informationalMeta(code: metaCode, message: fallback)
        }
        throw ServiceError.customError(fallback)
    }
}

enum ServiceError: Error {
    case customError(String)
    case dataProcessingError
    case informationalMeta(code: Int, message: String)
    case httpStatus(Int)
}

enum StateCode: Int {
    case informational = 100
    case success = 200
}
