import WebKit

/// WKWebView oturum cookie'lerini uygulama kapanışları arasında kalıcılaştırır.
enum WebCookieStore {
    private static let storageKey = AppConstants.cookieStorageKey
    private static let authCookieNames: Set<String> = [
        ".AspNetCore.Identity.Application",
        "EduKidGames.Identity.Application"
    ]
    private static let sessionLifetime: TimeInterval = 30 * 24 * 60 * 60

    private struct StoredCookie: Codable {
        let name: String
        let value: String
        let domain: String
        let path: String
        let expires: Date?
        let isSecure: Bool
        let isHTTPOnly: Bool
        let sameSitePolicy: String?

        init(cookie: HTTPCookie) {
            name = cookie.name
            value = cookie.value
            domain = cookie.domain
            path = cookie.path
            expires = cookie.expiresDate
            isSecure = cookie.isSecure
            isHTTPOnly = cookie.isHTTPOnly
            sameSitePolicy = cookie.sameSitePolicy?.rawValue
        }

        func makeHTTPCookie(refreshAuthExpiry: Bool) -> HTTPCookie? {
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
                .secure: isSecure ? "TRUE" : "FALSE"
            ]

            if isHTTPOnly {
                properties[.init("HttpOnly")] = "TRUE"
            }

            if let sameSitePolicy, !sameSitePolicy.isEmpty {
                properties[.sameSitePolicy] = sameSitePolicy
            }

            if refreshAuthExpiry && WebCookieStore.authCookieNames.contains(name) {
                let renewed = Date().addingTimeInterval(WebCookieStore.sessionLifetime)
                properties[.expires] = renewed
                properties[.maximumAge] = Int(WebCookieStore.sessionLifetime)
            } else if let expires {
                properties[.expires] = expires
            }

            return HTTPCookie(properties: properties)
        }
    }

    static var hasStoredSession: Bool {
        guard let cookies = loadStoredCookies() else { return false }
        return cookies.contains { authCookieNames.contains($0.name) && !$0.value.isEmpty }
    }

    static func persist(from store: WKHTTPCookieStore, completion: (() -> Void)? = nil) {
        store.getAllCookies { cookies in
            let stored = cookies.map(StoredCookie.init(cookie:))
            guard !stored.isEmpty else {
                UserDefaults.standard.removeObject(forKey: storageKey)
                DispatchQueue.main.async { completion?() }
                return
            }

            if let data = try? JSONEncoder().encode(stored) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
            DispatchQueue.main.async { completion?() }
        }
    }

    static func restore(into store: WKHTTPCookieStore, completion: @escaping () -> Void) {
        guard let stored = loadStoredCookies(), !stored.isEmpty else {
            DispatchQueue.main.async(execute: completion)
            return
        }

        let cookies = stored.compactMap { $0.makeHTTPCookie(refreshAuthExpiry: true) }
        guard !cookies.isEmpty else {
            DispatchQueue.main.async(execute: completion)
            return
        }

        let group = DispatchGroup()
        for cookie in cookies {
            group.enter()
            store.setCookie(cookie) { group.leave() }
        }
        group.notify(queue: .main, execute: completion)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    static func clearAll(in store: WKHTTPCookieStore, completion: (() -> Void)? = nil) {
        clear()
        store.getAllCookies { cookies in
            guard !cookies.isEmpty else {
                DispatchQueue.main.async { completion?() }
                return
            }
            let group = DispatchGroup()
            for cookie in cookies {
                group.enter()
                store.delete(cookie) { group.leave() }
            }
            group.notify(queue: .main) {
                completion?()
            }
        }
    }

    private static func loadStoredCookies() -> [StoredCookie]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }

        if let decoded = try? JSONDecoder().decode([StoredCookie].self, from: data) {
            return decoded
        }

        // Eski NSKeyedArchiver formatından tek seferlik geçiş
        return migrateLegacyArchive(data)
    }

    private static func migrateLegacyArchive(_ data: Data) -> [StoredCookie]? {
        let allowedClasses: [AnyClass] = [
            NSArray.self, NSDictionary.self, NSString.self,
            NSDate.self, NSNumber.self, NSURL.self
        ]
        guard let dicts = (try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: allowedClasses,
            from: data
        )) as? [[String: Any]] else { return nil }

        let cookies: [StoredCookie] = dicts.compactMap { dict in
            var properties: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in dict {
                properties[HTTPCookiePropertyKey(key)] = value
            }
            guard let cookie = HTTPCookie(properties: properties) else { return nil }
            return StoredCookie(cookie: cookie)
        }

        if !cookies.isEmpty, let encoded = try? JSONEncoder().encode(cookies) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        return cookies.isEmpty ? nil : cookies
    }
}
