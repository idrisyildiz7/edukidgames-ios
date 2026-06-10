import Foundation
import SwiftUI

@MainActor
final class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published private(set) var currentUser: StudentAuthData?
    private(set) var allowsDeviceTokenRegistration = false

    private(set) var accessToken: String?
    private(set) var userId: String?

    nonisolated static var persistedToken: String? {
        UserDefaults.standard.string(forKey: AppConstants.authTokenKey)
    }

    nonisolated static var persistedUserId: String? {
        UserDefaults.standard.string(forKey: AppConstants.authUserIdKey)
    }

    private init() {
        accessToken = nil
        userId = nil
        currentUser = nil
    }

    var isLoggedIn: Bool {
        guard let accessToken, !accessToken.isEmpty,
              let userId, !userId.isEmpty else { return false }
        return true
    }

    var hasSavedCredentials: Bool {
        savedCredentials() != nil
    }

    var isGuestSession: Bool {
        UserDefaults.standard.bool(forKey: AppConstants.authIsGuestKey)
    }

    func saveStudentCredentials(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: AppConstants.authEmailKey)
        UserDefaults.standard.set(password, forKey: AppConstants.authPasswordKey)
        UserDefaults.standard.set(false, forKey: AppConstants.authIsGuestKey)
    }

    func saveGuestCredentials() {
        UserDefaults.standard.removeObject(forKey: AppConstants.authEmailKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authPasswordKey)
        UserDefaults.standard.set(true, forKey: AppConstants.authIsGuestKey)
    }

    func savedCredentials() -> SavedLoginCredentials? {
        if UserDefaults.standard.bool(forKey: AppConstants.authIsGuestKey) {
            return .guest
        }
        let email = UserDefaults.standard.string(forKey: AppConstants.authEmailKey) ?? ""
        let password = UserDefaults.standard.string(forKey: AppConstants.authPasswordKey) ?? ""
        guard !email.isEmpty, !password.isEmpty else { return nil }
        return .student(email: email, password: password)
    }

    func clearActiveSession() {
        allowsDeviceTokenRegistration = false
        accessToken = nil
        userId = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: AppConstants.authTokenKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authUserIdKey)
        WebCookieStore.clear()
        AppDelegate.resetRegisteredFCMToken()
    }

    func clear() {
        clearActiveSession()
        UserDefaults.standard.removeObject(forKey: AppConstants.authEmailKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authPasswordKey)
        UserDefaults.standard.removeObject(forKey: AppConstants.authIsGuestKey)
    }

    func updateSession(with userData: StudentAuthData) {
        accessToken = userData.accessToken
        userId = userData.userId
        currentUser = userData
        UserDefaults.standard.set(userData.accessToken, forKey: AppConstants.authTokenKey)
        UserDefaults.standard.set(userData.userId, forKey: AppConstants.authUserIdKey)
    }

    func completeAuthenticatedSession(
        auth: StudentAuthData,
        authService: AuthServiceProtocol = AuthService.shared
    ) async throws {
        try await authService.establishWebSession(accessToken: auth.accessToken)
        updateSession(with: auth)
        guard !isGuestSession else { return }
        allowsDeviceTokenRegistration = true
        AppDelegate.sendDeviceTokenToServerIfNeeded()
    }

    func loginWithSavedCredentials(authService: AuthServiceProtocol = AuthService.shared) async throws -> StudentAuthData {
        switch savedCredentials() {
        case .student(let email, let password):
            return try await authService.studentLogin(email: email, password: password)
        case .guest:
            return try await authService.guestStudentLogin()
        case .none:
            throw AuthError.server("Kayıtlı giriş bilgisi bulunamadı.")
        }
    }
}
