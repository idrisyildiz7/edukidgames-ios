import SwiftUI

struct RootView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false
    @State private var showSplash = true
    @State private var isLoggedIn: Bool? = nil
    @State private var deepLinkRoute: String?

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else if isLoggedIn == true {
                StudentWebViewContainer(deepLinkRoute: deepLinkRoute)
            } else {
                LoginView(onLoggedIn: { isLoggedIn = true })
            }
        }
        .onAppear {
            startSplashTimer()
            if hasSeenOnboarding { restoreSession() }
        }
        .onChange(of: hasSeenOnboarding) { seen in
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
        guard isLoggedIn != true else { return }
        guard AuthSessionStore.isLoggedIn, AuthSessionStore.accessToken != nil else {
            isLoggedIn = false
            return
        }
        Task {
            do {
                try await withTimeout(seconds: 10) {
                    guard let token = AuthSessionStore.accessToken else { return }
                    try await AuthService.establishWebSession(accessToken: token)
                    AppDelegate.sendDeviceTokenToServerIfNeeded()
                }
                await MainActor.run { isLoggedIn = true }
            } catch {
                AuthSessionStore.clear()
                await MainActor.run { isLoggedIn = false }
            }
        }
    }
}

private func withTimeout(seconds: TimeInterval, operation: @escaping () async throws -> Void) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw URLError(.timedOut)
        }
        try await group.next()
        group.cancelAll()
    }
}
