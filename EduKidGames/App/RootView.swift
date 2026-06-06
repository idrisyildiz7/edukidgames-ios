import SwiftUI

struct RootView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else {
                StudentWebViewContainer()
            }
        }
        .onAppear { startSplashTimer() }
    }

    private func startSplashTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.splashDuration) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
        }
    }
}
