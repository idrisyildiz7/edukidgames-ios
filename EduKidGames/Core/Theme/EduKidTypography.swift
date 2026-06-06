import SwiftUI

enum EduKidTypography {
    private static let fredoka = "Fredoka-Light"
    private static let nunito = "Nunito-ExtraLight"

    static let displayLarge = Font.custom(fredoka, size: 28).weight(.bold)
    static let headlineLarge = Font.custom(fredoka, size: 26).weight(.bold)
    static let bodyMedium = Font.custom(nunito, size: 16).weight(.semibold)
    static let labelLarge = Font.custom(fredoka, size: 17).weight(.bold)
    static let splashTitle = Font.custom(fredoka, size: 34).weight(.bold)
    static let splashSubtitle = Font.custom(fredoka, size: 22).weight(.semibold)

    static let onboardingTitle = Font.custom(fredoka, size: 24).weight(.bold)
    static let onboardingBody = Font.custom(nunito, size: 15).weight(.semibold)
}
