import Foundation

enum AuthSessionStore {
    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: AppConstants.authTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.authTokenKey) }
    }

    static var userId: String? {
        get { UserDefaults.standard.string(forKey: AppConstants.authUserIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.authUserIdKey) }
    }

    static var isLoggedIn: Bool {
        guard let token = accessToken, !token.isEmpty,
              let uid = userId, !uid.isEmpty else { return false }
        return true
    }

    static func save(accessToken: String, userId: String) {
        self.accessToken = accessToken
        self.userId = userId
    }

    static func clear() {
        accessToken = nil
        userId = nil
        WebCookieStore.clear()
    }
}
