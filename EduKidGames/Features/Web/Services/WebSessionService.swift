import Foundation
import WebKit

enum WebSessionService {
    static func storeCookies(from response: HTTPURLResponse, baseURL: String = AppConstants.apiBaseURL) async {
        guard let headerFields = response.allHeaderFields as? [String: String],
              let urlHost = URL(string: baseURL) else { return }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: urlHost)
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            await store.setCookie(cookie)
        }
    }

    static func hasIdentityCookie(baseURL: String = AppConstants.apiBaseURL) async -> Bool {
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
