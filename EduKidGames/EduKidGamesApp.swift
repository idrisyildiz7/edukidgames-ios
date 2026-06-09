import SwiftUI

@main
struct EduKidGamesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .font(EduKidTypography.bodyMedium)
                .preferredColorScheme(.light)
        }
    }
}
