import SwiftUI

private struct OnboardingPage: Identifiable {
    let id: Int
    let imageName: String
    let titleKey: String
    let subtitleKey: String
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(id: 0, imageName: "OnboardHero", titleKey: "onboard.1.title", subtitleKey: "onboard.1.subtitle"),
    OnboardingPage(id: 1, imageName: "OnboardGamification", titleKey: "onboard.2.title", subtitleKey: "onboard.2.subtitle"),
    OnboardingPage(id: 2, imageName: "OnboardTracking", titleKey: "onboard.3.title", subtitleKey: "onboard.3.subtitle"),
    OnboardingPage(id: 3, imageName: "OnboardSafety", titleKey: "onboard.4.title", subtitleKey: "onboard.4.subtitle")
]

struct OnboardingView: View {
    @AppStorage(AppConstants.onboardingSeenKey) private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private var isLastPage: Bool { currentPage == onboardingPages.count - 1 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [EduKidColors.gradientTop, EduKidColors.cream, EduKidColors.gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    EduKidLogoHorizontal(height: 44, maxWidth: 200)
                    Spacer()
                    if !isLastPage {
                        Button(String(localized: "onboarding.skip")) {
                            hasSeenOnboarding = true
                        }
                        .font(EduKidTypography.bodyMedium)
                        .foregroundStyle(EduKidColors.onSurfaceVariant)
                    }
                }
                .padding(.horizontal, EduKidSpacing.screenPadding)
                .padding(.top, 8)

                TabView(selection: $currentPage) {
                    ForEach(onboardingPages) { page in
                        OnboardingPageView(page: page, isActive: currentPage == page.id)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.86), value: currentPage)

                VStack(spacing: EduKidSpacing.spacingLg) {
                    OnboardingPageIndicator(
                        pageCount: onboardingPages.count,
                        currentPage: currentPage
                    )
                    EduKidPrimaryButton(
                        title: String(localized: isLastPage ? "onboarding.button" : "onboarding.next")
                    ) {
                        if isLastPage {
                            hasSeenOnboarding = true
                        } else {
                            withAnimation { currentPage += 1 }
                        }
                    }
                    .padding(.horizontal, EduKidSpacing.screenPadding)
                }
                .padding(.bottom, 24)
            }
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            let cardSide = min(proxy.size.width * 0.78, proxy.size.height * 0.48, 280)

            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(EduKidColors.paper)
                        .shadow(color: EduKidColors.navy.opacity(0.08), radius: 20, x: 0, y: 14)
                    Image(page.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardSide * 0.82, height: cardSide * 0.82)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .frame(width: cardSide, height: cardSide)
                .scaleEffect(isActive ? 1 : 0.92)
                .animation(.spring(response: 0.45, dampingFraction: 0.78), value: isActive)

                VStack(spacing: 10) {
                    Text(LocalizedStringKey(page.titleKey))
                        .font(EduKidTypography.displayLarge)
                        .foregroundStyle(EduKidColors.navy)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(LocalizedStringKey(page.subtitleKey))
                        .font(EduKidTypography.bodyMedium)
                        .foregroundStyle(EduKidColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, EduKidSpacing.spacingXl)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
