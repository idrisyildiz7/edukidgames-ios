import Foundation
import SwiftyJSON

struct StudentAuthData: Equatable {
    let accessToken: String
    let userId: String
    let studentId: Int
    let fullName: String

    init(accessToken: String, userId: String, studentId: Int, fullName: String) {
        self.accessToken = accessToken
        self.userId = userId
        self.studentId = studentId
        self.fullName = fullName
    }

    init(json: JSON) throws {
        let data = json["data"]
        guard let accessToken = data["accessToken"].string,
              let userId = data["userId"].string,
              let fullName = data["fullName"].string else {
            throw AuthError.server("Sunucu yanıtı eksik veya hatalı.")
        }
        let studentId = data["studentId"].int ?? Int(data["studentId"].stringValue)
        guard let studentId else {
            throw AuthError.server("Sunucu yanıtı eksik veya hatalı.")
        }
        self.init(accessToken: accessToken, userId: userId, studentId: studentId, fullName: fullName)
    }
}

struct StudentLoginRequest {
    let email: String
    let password: String

    func toParameters() -> [String: Any] {
        [
            "email": email,
            "password": password,
            "appPlatform": "ios"
        ]
    }
}

struct DeviceTokenRequest {
    let token: String
    let platform: String
    let userId: String

    func toParameters() -> [String: Any] {
        [
            "token": token,
            "platform": platform,
            "userId": userId
        ]
    }
}

struct LoginFormModel {
    var email = ""
    var password = ""
}

enum SavedLoginCredentials {
    case student(email: String, password: String)
    case guest
}

enum AuthError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Sunucudan geçersiz yanıt alındı."
        case .server(let msg): return msg
        }
    }
}
