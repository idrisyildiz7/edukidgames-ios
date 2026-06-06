import SwiftUI

private struct OnboardingPage: Identifiable {
    let id: Int
    let imageName: String
    let titleKey: String
    let subtitleKey: String
    let style: OnboardVisualStyle
}

private struct OnboardVisualStyle {
    let cardTop: Color
    let cardBottom: Color
    let ambient: Color
    let shadow: Color
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        id: 0, imageName: "OnboardHero",
        titleKey: "onboard.1.title", subtitleKey: "onboard.1.subtitle",
        style: OnboardVisualStyle(
            cardTop: Color(red: 1.0, green: 0.94, blue: 0.96),
            cardBottom: Color(red: 1.0, green: 0.97, blue: 0.91),
            ambient: Color(red: 1.0, green: 0.62, blue: 0.45).opacity(0.22),
            shadow: Color(red: 0.92, green: 0.45, blue: 0.55).opacity(0.18)
        )
    ),
    OnboardingPage(
        id: 1, imageName: "OnboardGamification",
        titleKey: "onboard.2.title", subtitleKey: "onboard.2.subtitle",
        style: OnboardVisualStyle(
            cardTop: Color(red: 1.0, green: 0.97, blue: 0.88),
            cardBottom: Color(red: 1.0, green: 0.93, blue: 0.78),
            ambient: Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.24),
            shadow: Color(red: 0.95, green: 0.58, blue: 0.1).opacity(0.2)
        )
    ),
    OnboardingPage(
        id: 2, imageName: "OnboardTracking",
        titleKey: "onboard.3.title", subtitleKey: "onboard.3.subtitle",
        style: OnboardVisualStyle(
            cardTop: Color(red: 0.9, green: 0.97, blue: 0.99),
            cardBottom: Color(red: 0.93, green: 0.94, blue: 1.0),
            ambient: Color(red: 0.18, green: 0.77, blue: 0.71).opacity(0.2),
            shadow: Color(red: 0.12, green: 0.55, blue: 0.62).opacity(0.16)
        )
    ),
    OnboardingPage(
        id: 3, imageName: "OnboardSafety",
        titleKey: "onboard.4.title", subtitleKey: "onboard.4.subtitle",
        style: OnboardVisualStyle(
            cardTop: Color(red: 0.92, green: 0.98, blue: 0.94),
            cardBottom: Color(red: 0.9, green: 0.97, blue: 0.96),
            ambient: Color(red: 0.45, green: 0.78, blue: 0.55).opacity(0.22),
            shadow: Color(red: 0.22, green: 0.58, blue: 0.42).opacity(0.16)
        )
    )
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

                OnboardingPagingScroll(pageCount: onboardingPages.count, currentPage: $currentPage) { index, offset in
                    OnboardingPageView(page: onboardingPages[index], pageOffset: offset)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                                currentPage += 1
                            }
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
    let pageOffset: CGFloat

    private var focus: CGFloat { 1 - min(abs(pageOffset), 1) }
    private var parallaxX: CGFloat { pageOffset * -34 }
    private var floatY: CGFloat { pageOffset * 12 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 6)

            OnboardingIllustrationCard(
                imageName: page.imageName,
                style: page.style,
                focus: focus,
                parallaxX: parallaxX,
                floatY: floatY
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 22)

            VStack(spacing: 10) {
                Text(LocalizedStringKey(page.titleKey))
                    .font(EduKidTypography.onboardingTitle)
                    .foregroundStyle(EduKidColors.navy)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.88)
                    .offset(x: parallaxX * 0.35, y: floatY * 0.25)
                    .opacity(0.35 + focus * 0.65)

                Text(LocalizedStringKey(page.subtitleKey))
                    .font(EduKidTypography.onboardingBody)
                    .foregroundStyle(EduKidColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.9)
                    .offset(x: parallaxX * 0.2, y: floatY * 0.15)
                    .opacity(0.4 + focus * 0.6)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 6)

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingIllustrationCard: View {
    let imageName: String
    let style: OnboardVisualStyle
    let focus: CGFloat
    let parallaxX: CGFloat
    let floatY: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            style.cardTop.opacity(0.55),
                            style.cardBottom.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.65), lineWidth: 1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .padding(.horizontal, 8)
                .offset(y: 18)
                .opacity(0.85 + focus * 0.15)

            Ellipse()
                .fill(style.shadow.opacity(0.28))
                .frame(width: 200, height: 22)
                .blur(radius: 14)
                .offset(y: 6)
                .scaleEffect(0.75 + focus * 0.25)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 12)
                .offset(x: parallaxX, y: floatY - 6)
                .scaleEffect(0.86 + focus * 0.14)
                .rotationEffect(.degrees(Double(parallaxX * 0.05)))
                .shadow(color: style.shadow.opacity(0.35), radius: 28, x: parallaxX * 0.15, y: 18)
        }
        .frame(maxWidth: 360)
        .frame(height: 300)
    }
}
