import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    var onLoggedIn: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Hoş Geldin!")
                .font(EduKidTypography.headlineLarge)
                .foregroundStyle(EduKidColors.navy)
            Text("Devam etmek için giriş yap.")
                .font(EduKidTypography.bodyMedium)
                .foregroundStyle(EduKidColors.onSurfaceVariant)

            VStack(spacing: 12) {
                TextField("E-Posta", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                SecureField("Şifre", text: $password)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button(action: login) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Giriş Yap").fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(EduKidColors.orange)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .padding(.horizontal, 24)
            .disabled(isLoading)

            Spacer()
        }
        .background(
            LinearGradient(
                colors: [EduKidColors.gradientTop, EduKidColors.cream],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func login() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let auth = try await AuthService.studentLogin(email: email.trimmingCharacters(in: .whitespaces), password: password)
                try await AuthService.establishWebSession(accessToken: auth.accessToken)
                AuthSessionStore.save(accessToken: auth.accessToken, userId: auth.userId)
                AppDelegate.sendDeviceTokenToServerIfNeeded()
                await MainActor.run {
                    isLoading = false
                    onLoggedIn()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
