import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            EduKidScreenBackground()
            GeometryReader { proxy in
                let safeBottom = proxy.safeAreaInsets.bottom
                let heroSide = min(proxy.size.width * 0.82, proxy.size.height * 0.36, 320)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: max(proxy.safeAreaInsets.top, 16) + 16)
                        EduKidLogoHorizontal(height: 40)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, EduKidSpacing.screenPadding)

                        Spacer().frame(height: 24)
                        heroCard(side: heroSide)
                        Spacer().frame(height: 28)

                        VStack(spacing: EduKidSpacing.spacingSm) {
                            Text(String(localized: "onboarding.title"))
                                .font(EduKidTypography.headlineLarge)
                                .foregroundStyle(EduKidColors.navy)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(String(localized: "onboarding.subtitle"))
                                .font(EduKidTypography.bodyMedium)
                                .foregroundStyle(EduKidColors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, EduKidSpacing.spacingXl)

                        Spacer().frame(height: 28)
                        EduKidPrimaryButton(title: String(localized: "onboarding.button")) {
                            hasSeenOnboarding = true
                        }
                        .padding(.horizontal, EduKidSpacing.screenPadding)
                        Spacer().frame(height: max(safeBottom, 24) + 16)
                    }
                    .frame(minHeight: proxy.size.height)
                }
            }
        }
    }

    private func heroCard(side: CGFloat) -> some View {
        ZStack {
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
        .frame(maxWidth: .infinity)
    }
}
