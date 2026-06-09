import Foundation

enum AppConstants {
    #if DEBUG
    static let apiBaseURL = "http://127.0.0.1:5029"
    #else
    static let apiBaseURL = "https://edukidgames.com"
    #endif

    static var studentHomeURL: String { apiBaseURL + "/Student/Index?shell=webview" }
    static let logoutPathPrefix = "/Account/Logout"

    static let webViewUserAgent = "EduKidWebView/1.0 (iOS)"
    static let onboardingSeenKey = "edukid.onboarding.seen"
    static let cookieStorageKey = "edukid.student.webCookies"
    static let authTokenKey = "edukid.auth.token"
    static let authUserIdKey = "edukid.auth.userId"
    static let splashDuration: TimeInterval = 1.5
}
