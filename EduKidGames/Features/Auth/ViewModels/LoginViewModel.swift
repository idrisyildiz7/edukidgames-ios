import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var form = LoginFormModel()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol
    private let userManager: UserManager

    init(
        authService: AuthServiceProtocol = AuthService.shared,
        userManager: UserManager = .shared
    ) {
        self.authService = authService
        self.userManager = userManager
    }

    var trimmedEmail: String {
        form.email.trimmingCharacters(in: .whitespaces)
    }

    func login() {
        performLogin(credentialSaver: { [userManager, trimmedEmail, form] in
            userManager.saveStudentCredentials(email: trimmedEmail, password: form.password)
        }) { [authService, trimmedEmail, form] in
            try await authService.studentLogin(email: trimmedEmail, password: form.password)
        }
    }

    func guestLogin() {
        performLogin(credentialSaver: { [userManager] in
            userManager.saveGuestCredentials()
        }) { [authService] in
            try await authService.guestStudentLogin()
        }
    }

    private func performLogin(
        credentialSaver: @escaping () -> Void,
        authCall: @escaping () async throws -> StudentAuthData
    ) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        userManager.clearActiveSession()

        Task {
            do {
                let auth = try await authCall()
                credentialSaver()
                try await userManager.completeAuthenticatedSession(auth: auth, authService: authService)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
