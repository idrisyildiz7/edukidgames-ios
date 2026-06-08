import Foundation

enum AppConstants {
    static let loginURL = "https://edukidgames.com/Account/Login?shell=webview"
    static let studentHomeURL = "https://edukidgames.com/Student/Index?shell=webview"
    static let logoutPathPrefix = "/Account/Logout"

    static let webViewUserAgent = "EduKidWebView/1.0 (iOS)"
    static let onboardingSeenKey = "edukid.onboarding.seen"
    static let cookieStorageKey = "edukid.student.webCookies"
    static let splashDuration: TimeInterval = 1.5
}
