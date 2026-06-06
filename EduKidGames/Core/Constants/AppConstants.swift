import Foundation

enum AppConstants {
    #if DEBUG
    static let loginURL = "http://192.168.1.7:5029/Account/Login?shell=webview"
    #else
    static let loginURL = "https://edukidgames.com/Account/Login?shell=webview"
    #endif

    static let webViewUserAgent = "EduKidWebView/1.0 (iOS)"
    static let onboardingSeenKey = "edukid.onboarding.seen"
    static let cookieStorageKey = "edukid.student.webCookies"
    static let splashDuration: TimeInterval = 1.5
}
