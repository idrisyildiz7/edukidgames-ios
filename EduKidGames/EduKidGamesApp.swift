import SwiftUI

@main
struct EduKidGamesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var userManager = UserManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userManager)
                .font(EduKidTypography.bodyMedium)
                .preferredColorScheme(.light)
        }
    }
}
