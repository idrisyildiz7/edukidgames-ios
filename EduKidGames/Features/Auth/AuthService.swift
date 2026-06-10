import Foundation
import WebKit

struct StudentAuthResult {
    let accessToken: String
    let userId: String
    let studentId: Int
    let fullName: String
}

enum AuthService {
    /// Misafir: önce guest API, yoksa demo öğrenci student-login (canlıda guest genelde 404)
    static func guestStudentLogin() async throws -> StudentAuthResult {
        do {
            return try await postGuestStudentLogin()
        } catch {
            return try await studentLogin(
                email: AppConstants.demoStudentEmail,
                password: AppConstants.demoStudentPassword
            )
        }
    }

    private static func postGuestStudentLogin() async throws -> StudentAuthResult {
        let url = URL(string: AppConstants.apiBaseURL + "/api/auth/guest-student-login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if http.statusCode == 404 {
            throw AuthError.server("guest-endpoint-404")
        }

        let json = try parseJSONObject(data)
        if http.statusCode != 200 {
            let message = (json["meta"] as? [String: Any])?["message"] as? String
            throw AuthError.server(message ?? "Misafir girişi başarısız (\(http.statusCode))")
        }

        await storeCookies(from: http, baseURL: AppConstants.apiBaseURL)
        return try parseAuthResult(json)
    }

    static func studentLogin(email: String, password: String) async throws -> StudentAuthResult {
        let url = URL(string: AppConstants.apiBaseURL + "/api/auth/student-login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "password": password, "appPlatform": "ios"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if http.statusCode != 200 {
            if data.isEmpty {
                throw AuthError.server("Giriş başarısız (HTTP \(http.statusCode))")
            }
            if let json = try? parseJSONObject(data),
               let message = (json["meta"] as? [String: Any])?["message"] as? String {
                throw AuthError.server(message)
            }
            throw AuthError.server("Giriş başarısız (HTTP \(http.statusCode))")
        }

        let json = try parseJSONObject(data)
        await storeCookies(from: http, baseURL: AppConstants.apiBaseURL)
        return try parseAuthResult(json)
    }

    static func establishWebSession(accessToken: String) async throws {
        if await hasIdentityCookie(baseURL: AppConstants.apiBaseURL) {
            return
        }

        let url = URL(string: AppConstants.apiBaseURL + "/api/auth/establish-web-session")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = "{}".data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server("Web oturumu oluşturulamadı")
        }

        await storeCookies(from: http, baseURL: AppConstants.apiBaseURL)

        if http.statusCode == 200 {
            return
        }
        if await hasIdentityCookie(baseURL: AppConstants.apiBaseURL) {
            return
        }

        throw AuthError.server("Web oturumu oluşturulamadı")
    }

    @discardableResult
    static func registerDeviceToken(accessToken: String, userId: String, fcmToken: String) async -> Bool {
        let url = URL(string: AppConstants.apiBaseURL + "/api/mobile/device-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = ["token": fcmToken, "platform": "ios", "userId": userId]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return false }
        request.httpBody = bodyData
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return false
            }
            return true
        } catch {
            return false
        }
    }

    private static func parseJSONObject(_ data: Data) throws -> [String: Any] {
        guard !data.isEmpty else { throw AuthError.invalidResponse }
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AuthError.invalidResponse
            }
            return json
        } catch {
            throw AuthError.server("Sunucu yanıtı okunamadı. Lütfen tekrar deneyin.")
        }
    }

    private static func parseAuthResult(_ json: [String: Any]) throws -> StudentAuthResult {
        guard let payload = json["data"] as? [String: Any],
              let token = payload["accessToken"] as? String,
              let userId = payload["userId"] as? String,
              let studentId = parseInt(payload["studentId"]),
              let fullName = payload["fullName"] as? String else {
            throw AuthError.server("Sunucu yanıtı eksik veya hatalı.")
        }
        return StudentAuthResult(accessToken: token, userId: userId, studentId: studentId, fullName: fullName)
    }

    private static func parseInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String, let intValue = Int(string) { return intValue }
        return nil
    }

    private static func storeCookies(from response: HTTPURLResponse, baseURL: String) async {
        guard let headerFields = response.allHeaderFields as? [String: String],
              let urlHost = URL(string: baseURL) else { return }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: urlHost)
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            await store.setCookie(cookie)
        }
    }

    private static func hasIdentityCookie(baseURL: String) async -> Bool {
        guard let host = URL(string: baseURL)?.host else { return false }
        let store = WKWebsiteDataStore.default().httpCookieStore
        let cookies = await store.allCookies()
        return cookies.contains { cookie in
            (cookie.domain.contains(host) || host.contains(cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")))) &&
            (cookie.name.contains("Identity") || cookie.name.contains("Auth")) &&
            !cookie.value.isEmpty
        }
    }
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
