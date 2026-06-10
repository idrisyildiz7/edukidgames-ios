import SwiftUI

struct RootView: View {
    @EnvironmentObject private var userManager: UserManager
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false
    @State private var showSplash = true
    @State private var isAutoLogging = false
    @State private var deepLinkRoute: String?

    var body: some View {
        Group {
            if showSplash || isAutoLogging {
                SplashView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else if userManager.isLoggedIn {
                StudentWebViewContainer(deepLinkRoute: deepLinkRoute)
            } else {
                LoginView()
            }
        }
        .onAppear {
            startSplashTimer()
            if hasSeenOnboarding {
                attemptAutoLogin()
            }
        }
        .onChange(of: hasSeenOnboarding) { seen in
            if seen {
                attemptAutoLogin()
            }
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
        }
    }

    private func attemptAutoLogin() {
        guard !isAutoLogging else { return }
        guard !userManager.isLoggedIn else { return }
        guard userManager.hasSavedCredentials else { return }

        isAutoLogging = true
        userManager.clearActiveSession()

        Task {
            do {
                try await withTimeout(seconds: 15) {
                    let auth = try await userManager.loginWithSavedCredentials()
                    try await userManager.completeAuthenticatedSession(auth: auth)
                }
                isAutoLogging = false
            } catch {
                userManager.clear()
                isAutoLogging = false
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
