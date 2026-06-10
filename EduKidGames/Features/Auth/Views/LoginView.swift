import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            AuthLoginBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    EduKidLogoHorizontal(height: 52, maxWidth: 300, showShadow: true)
                        .padding(.top, 8)

                    loginCard
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private var loginCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                EduKidAstronautLogo(size: 78)

                AuthWelcomeTitle()

                Text("Devam etmek için giriş yap.")
                    .font(EduKidTypography.bodyMedium)
                    .foregroundStyle(EduKidColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 18)

            if let errorMessage = viewModel.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(red: 0.725, green: 0.11, blue: 0.11))
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.725, green: 0.11, blue: 0.11))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.bottom, 14)
            }

            VStack(spacing: 14) {
                AuthInputField(
                    title: "E-Posta Adresi",
                    placeholder: "ornek@hesap.com",
                    systemImage: "envelope.fill",
                    text: $viewModel.form.email
                )

                AuthInputField(
                    title: "Şifre",
                    placeholder: "••••••••",
                    systemImage: "lock.fill",
                    text: $viewModel.form.password,
                    isSecure: true
                )
            }

            Button(action: viewModel.login) {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sisteme Giriş Yap")
                            .font(EduKidTypography.labelLarge)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(
                LinearGradient(
                    colors: [EduKidColors.orange, Color(red: 0.878, green: 0.486, blue: 0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: EduKidColors.orange.opacity(0.35), radius: 11, y: 6)
            .padding(.top, 18)
            .disabled(viewModel.isLoading)

            HStack(spacing: 10) {
                Rectangle()
                    .fill(EduKidColors.orange.opacity(0.18))
                    .frame(height: 1)
                Text("veya")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(EduKidColors.onSurfaceVariant)
                Rectangle()
                    .fill(EduKidColors.orange.opacity(0.18))
                    .frame(height: 1)
            }
            .padding(.vertical, 16)

            Button(action: viewModel.guestLogin) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Misafir olarak devam et")
                        .font(EduKidTypography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.98), Color(red: 0.925, green: 0.992, blue: 0.961)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundStyle(Color(red: 0.059, green: 0.463, blue: 0.431))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(EduKidColors.teal.opacity(0.55), lineWidth: 2)
            )
            .shadow(color: EduKidColors.teal.opacity(0.16), radius: 8, y: 4)
            .disabled(viewModel.isLoading)

            Text("Demo öğrenci hesabıyla hızlıca giriş yap")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(EduKidColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .background(Color.white.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(EduKidColors.outline, lineWidth: 1)
        )
        .shadow(color: EduKidColors.navy.opacity(0.1), radius: 16, y: 8)
    }
}
