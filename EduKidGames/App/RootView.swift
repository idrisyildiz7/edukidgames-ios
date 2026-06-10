import SwiftUI

struct RootView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false
    @State private var showSplash = true
    @State private var isAutoLogging = false
    @State private var isLoggedIn: Bool? = nil
    @State private var deepLinkRoute: String?

    var body: some View {
        Group {
            if showSplash || isAutoLogging {
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
            if hasSeenOnboarding { attemptAutoLogin() }
        }
        .onChange(of: hasSeenOnboarding) { seen in
            if seen { attemptAutoLogin() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .edukidPushDeepLink)) { note in
            deepLinkRoute = note.object as? String
        }
    }

    private func startSplashTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.splashDuration) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
            if hasSeenOnboarding { attemptAutoLogin() }
        }
    }

    private func attemptAutoLogin() {
        guard isLoggedIn != true else { return }
        guard AuthSessionStore.hasSavedCredentials else {
            isLoggedIn = false
            return
        }

        isAutoLogging = true
        AuthSessionStore.clearActiveSession()
        Task {
            do {
                try await withTimeout(seconds: 15) {
                    let auth = try await AuthSessionStore.loginWithSavedCredentials()
                    try await AuthSessionStore.completeAuthenticatedSession(auth: auth)
                }
                await MainActor.run {
                    isAutoLogging = false
                    isLoggedIn = true
                }
            } catch {
                AuthSessionStore.clear()
                await MainActor.run {
                    isAutoLogging = false
                    isLoggedIn = false
                }
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
