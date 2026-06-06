import SwiftUI

@main
struct EduKidGamesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .font(EduKidTypography.bodyMedium)
                .preferredColorScheme(.light)
        }
    }
}
