import WebKit

/// WKWebView oturum cookie'lerini uygulama kapanışları arasında kalıcılaştırır.
enum WebCookieStore {
    private static let storageKey = AppConstants.cookieStorageKey

    static func persist(from store: WKHTTPCookieStore) {
        store.getAllCookies { cookies in
            let dicts: [[String: Any]] = cookies.compactMap { cookie in
                guard let properties = cookie.properties else { return nil }
                var dict: [String: Any] = [:]
                for (key, value) in properties {
                    dict[key.rawValue] = value
                }
                return dict
            }
            guard let data = try? NSKeyedArchiver.archivedData(
                withRootObject: dicts,
                requiringSecureCoding: true
            ) else { return }
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func restore(into store: WKHTTPCookieStore, completion: @escaping () -> Void) {
        let cookies = load()
        guard !cookies.isEmpty else {
            completion()
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

    private static func load() -> [HTTPCookie] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        let allowedClasses: [AnyClass] = [
            NSArray.self, NSDictionary.self, NSString.self,
            NSDate.self, NSNumber.self, NSURL.self
        ]
        guard let dicts = (try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: allowedClasses,
            from: data
        )) as? [[String: Any]] else { return [] }

        return dicts.compactMap { dict in
            var properties: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in dict {
                properties[HTTPCookiePropertyKey(key)] = value
            }
            return HTTPCookie(properties: properties)
        }
    }
}
