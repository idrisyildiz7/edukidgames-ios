import Foundation
import WebKit

struct StudentAuthResult {
    let accessToken: String
    let userId: String
    let studentId: Int
    let fullName: String
}

enum AuthService {
    static func studentLogin(email: String, password: String) async throws -> StudentAuthResult {
        let url = URL(string: AppConstants.apiBaseURL + "/api/auth/student-login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "password": password, "appPlatform": "ios"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        if http.statusCode != 200 {
            let message = (json?["meta"] as? [String: Any])?["message"] as? String
            throw AuthError.server(message ?? "Giriş başarısız")
        }

        guard let payload = json?["data"] as? [String: Any],
              let token = payload["accessToken"] as? String,
              let userId = payload["userId"] as? String,
              let studentId = payload["studentId"] as? Int,
              let fullName = payload["fullName"] as? String else {
            throw AuthError.invalidResponse
        }

        return StudentAuthResult(accessToken: token, userId: userId, studentId: studentId, fullName: fullName)
    }

    static func establishWebSession(accessToken: String) async throws {
        let url = URL(string: AppConstants.apiBaseURL + "/api/auth/establish-web-session")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.server("Web oturumu oluşturulamadı")
        }

        if let headerFields = http.allHeaderFields as? [String: String],
           let urlHost = URL(string: AppConstants.apiBaseURL) {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: urlHost)
            let store = WKWebsiteDataStore.default().httpCookieStore
            for cookie in cookies {
                await store.setCookie(cookie)
            }
        }
    }

    static func registerDeviceToken(accessToken: String, userId: String, fcmToken: String) async {
        let url = URL(string: AppConstants.apiBaseURL + "/api/mobile/device-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = ["token": fcmToken, "platform": "ios", "userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
}

enum AuthError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Geçersiz sunucu yanıtı"
        case .server(let msg): return msg
        }
    }
}
