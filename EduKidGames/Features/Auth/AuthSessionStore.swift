import Foundation

enum SavedLoginCredentials {
    case student(email: String, password: String)
    case guest
}

enum AuthSessionStore {
    private(set) static var allowsDeviceTokenRegistration = false

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

    static var hasSavedCredentials: Bool {
        savedCredentials() != nil
    }

    static func save(accessToken: String, userId: String) {
        self.accessToken = accessToken
        self.userId = userId
    }

    static func saveStudentCredentials(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: AppConstants.authEmailKey)
        UserDefaults.standard.set(password, forKey: AppConstants.authPasswordKey)
        UserDefaults.standard.set(false, forKey: AppConstants.authIsGuestKey)
    }

    static func saveGuestCredentials() {
        UserDefaults.standard.removeObject(forKey: AppConstants.authEmailKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authPasswordKey)
        UserDefaults.standard.set(true, forKey: AppConstants.authIsGuestKey)
    }

    static func savedCredentials() -> SavedLoginCredentials? {
        if UserDefaults.standard.bool(forKey: AppConstants.authIsGuestKey) {
            return .guest
        }
        let email = UserDefaults.standard.string(forKey: AppConstants.authEmailKey) ?? ""
        let password = UserDefaults.standard.string(forKey: AppConstants.authPasswordKey) ?? ""
        guard !email.isEmpty, !password.isEmpty else { return nil }
        return .student(email: email, password: password)
    }

    static func clearActiveSession() {
        allowsDeviceTokenRegistration = false
        accessToken = nil
        userId = nil
        WebCookieStore.clear()
    }

    static func clear() {
        clearActiveSession()
        UserDefaults.standard.removeObject(forKey: AppConstants.authEmailKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authPasswordKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authIsGuestKey)
    }

    static func completeAuthenticatedSession(auth: StudentAuthResult) async throws {
        try await AuthService.establishWebSession(accessToken: auth.accessToken)
        save(accessToken: auth.accessToken, userId: auth.userId)
        allowsDeviceTokenRegistration = true
        AppDelegate.sendDeviceTokenToServerIfNeeded()
    }

    static func loginWithSavedCredentials() async throws -> StudentAuthResult {
        switch savedCredentials() {
        case .student(let email, let password):
            return try await AuthService.studentLogin(email: email, password: password)
        case .guest:
            return try await AuthService.guestStudentLogin()
        case .none:
            throw AuthError.server("Kayıtlı giriş bilgisi bulunamadı.")
        }
    }
}
