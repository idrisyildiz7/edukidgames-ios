import Alamofire
import Foundation

protocol AuthServiceProtocol {
    func guestStudentLogin() async throws -> StudentAuthData
    func studentLogin(email: String, password: String) async throws -> StudentAuthData
    func establishWebSession(accessToken: String) async throws
    func registerDeviceToken(accessToken: String, userId: String, fcmToken: String) async -> Bool
}

final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private let networking: Networking

    private init(networking: Networking = .shared) {
        self.networking = networking
    }

    func guestStudentLogin() async throws -> StudentAuthData {
        do {
            return try await postGuestStudentLogin()
        } catch {
            return try await studentLogin(
                email: AppConstants.demoStudentEmail,
                password: AppConstants.demoStudentPassword
            )
        }
    }

    private func postGuestStudentLogin() async throws -> StudentAuthData {
        do {
            let (json, response) = try await networking.requestWithHTTPResponse(
                method: .post,
                url: AppConstants.guestStudentLoginURL,
                parameters: [:]
            )
            await WebSessionService.storeCookies(from: response)
            return try StudentAuthData(json: json)
        } catch {
            throw mapError(error)
        }
    }

    func studentLogin(email: String, password: String) async throws -> StudentAuthData {
        do {
            let request = StudentLoginRequest(email: email, password: password)
            let (json, response) = try await networking.requestWithHTTPResponse(
                method: .post,
                url: AppConstants.studentLoginURL,
                parameters: request.toParameters()
            )
            await WebSessionService.storeCookies(from: response)
            return try StudentAuthData(json: json)
        } catch {
            throw mapError(error)
        }
    }

    func establishWebSession(accessToken: String) async throws {
        if await WebSessionService.hasIdentityCookie() {
            return
        }

        do {
            let (_, response) = try await networking.requestWithHTTPResponse(
                method: .post,
                url: AppConstants.establishWebSessionURL,
                parameters: [:],
                bearerToken: accessToken
            )
            await WebSessionService.storeCookies(from: response)
        } catch {
            if await WebSessionService.hasIdentityCookie() {
                return
            }
            throw mapError(error)
        }
    }

    @discardableResult
    func registerDeviceToken(accessToken: String, userId: String, fcmToken: String) async -> Bool {
        let request = DeviceTokenRequest(token: fcmToken, platform: "ios", userId: userId)
        do {
            _ = try await networking.request(
                method: .post,
                url: AppConstants.deviceTokenURL,
                parameters: request.toParameters(),
                bearerToken: accessToken
            )
            return true
        } catch {
            return false
        }
    }

    private func mapError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        if let serviceError = error as? ServiceError {
            return .server(serviceError.messageText)
        }
        return .server(error.localizedDescription)
    }
}
