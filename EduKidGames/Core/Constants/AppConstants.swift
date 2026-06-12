import Foundation

enum AppConstants {
    #if DEBUG
    #if targetEnvironment(simulator)
    static let apiBaseURL = "https://edukidgames.com"
    #else
    // Fiziksel cihaz: canlı sunucu (yerel IP/Mac sunucusu güvenilir değil)
    static let apiBaseURL = "https://edukidgames.com"
    #endif
    #else
    static let apiBaseURL = "https://edukidgames.com"
    #endif

    static var studentHomeURL: String { apiBaseURL + "/Student/Index?shell=webview" }
    static var guestStudentLoginURL: String { apiBaseURL + "/api/auth/guest-student-login" }
    static var studentLoginURL: String { apiBaseURL + "/api/auth/student-login" }
    static var establishWebSessionURL: String { apiBaseURL + "/api/auth/establish-web-session" }
    static var deviceTokenURL: String { apiBaseURL + "/api/mobile/device-token" }
    static let logoutPathPrefix = "/Account/Logout"
    static let nativeBridgeHandlerName = "edukidNative"
    static let nativeBridgeLogoutType = "logout"
    static let nativeBridgeDeleteAccountType = "delete_account"

    static let webViewUserAgent = "EduKidWebView/1.0 (iOS)"
    static let onboardingSeenKey = "edukid.onboarding.seen"
    static let cookieStorageKey = "edukid.student.webCookies"
    static let authTokenKey = "edukid.auth.token"
    static let authUserIdKey = "edukid.auth.userId"
    static let authEmailKey = "edukid.auth.email"
    static let authPasswordKey = "edukid.auth.password"
    static let authIsGuestKey = "edukid.auth.isGuest"
    static let splashDuration: TimeInterval = 1.5

    /// Misafir endpoint yoksa fallback (sunucu DemoUsers ile aynı)
    static let demoStudentEmail = "ogrenci@edukidgames.com"
    static let demoStudentPassword = "Password123!"
}
