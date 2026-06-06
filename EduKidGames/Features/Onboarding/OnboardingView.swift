import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            EduKidScreenBackground()
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Spacer().frame(height: 32)
                    EduKidLogoHorizontal(height: 44)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, EduKidSpacing.screenPadding)
                    Spacer()
                    heroCard(available: proxy.size)
                    Spacer()
                    VStack(spacing: EduKidSpacing.spacingSm) {
                        Text(String(localized: "onboarding.title"))
                            .font(EduKidTypography.headlineLarge)
                            .foregroundStyle(EduKidColors.navy)
                            .multilineTextAlignment(.center)
                        Text(String(localized: "onboarding.subtitle"))
                            .font(EduKidTypography.bodyMedium)
                            .foregroundStyle(EduKidColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, EduKidSpacing.spacingXl)
                    Spacer().frame(height: EduKidSpacing.spacingXl)
                    EduKidPrimaryButton(title: String(localized: "onboarding.button")) {
                        hasSeenOnboarding = true
                    }
                    .padding(.horizontal, EduKidSpacing.screenPadding)
                    .padding(.bottom, EduKidSpacing.spacingXl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func heroCard(available: CGSize) -> some View {
        let side = min(available.width * 0.82, available.height * 0.42)
        return ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(EduKidColors.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(EduKidColors.outline, lineWidth: 1)
                )
                .shadow(color: EduKidColors.navy.opacity(0.06), radius: 18, x: 0, y: 12)
            Image("Hero")
                .resizable()
                .scaledToFit()
                .frame(width: side * 0.88, height: side * 0.88)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .frame(width: side, height: side)
    }
}
