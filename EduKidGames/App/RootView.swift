import SwiftUI

struct RootView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false
    @State private var showSplash = true
    @State private var isLoggedIn: Bool? = nil
    @State private var deepLinkRoute: String?

    var body: some View {
        Group {
            if showSplash || (hasSeenOnboarding && isLoggedIn == nil) {
                SplashView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else if isLoggedIn == false {
                LoginView(onLoggedIn: { isLoggedIn = true })
            } else {
                StudentWebViewContainer(deepLinkRoute: deepLinkRoute)
            }
        }
        .onAppear { startSplashTimer() }
        .onChange(of: hasSeenOnboarding) { _, seen in
            if seen { restoreSession() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .edukidPushDeepLink)) { note in
            deepLinkRoute = note.object as? String
        }
    }

    private func startSplashTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.splashDuration) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
                if hasSeenOnboarding { restoreSession() }
            }
        }
    }

    private func restoreSession() {
        guard isLoggedIn == nil else { return }
        guard AuthSessionStore.isLoggedIn, let token = AuthSessionStore.accessToken else {
            isLoggedIn = false
            return
        }
        Task {
            do {
                try await AuthService.establishWebSession(accessToken: token)
                AppDelegate.sendDeviceTokenToServerIfNeeded()
                await MainActor.run { isLoggedIn = true }
            } catch {
                AuthSessionStore.clear()
                await MainActor.run { isLoggedIn = false }
            }
        }
    }
}
