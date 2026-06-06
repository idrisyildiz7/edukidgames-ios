import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [EduKidColors.gradientTop, EduKidColors.cream, EduKidColors.gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: EduKidSpacing.spacingMd) {
                EduKidAstronautLogo(size: 160)
                VStack(spacing: 4) {
                    Text("EduKid")
                        .font(EduKidTypography.splashTitle)
                        .foregroundStyle(EduKidColors.navy)
                    Text("Games")
                        .font(EduKidTypography.splashSubtitle)
                        .foregroundStyle(EduKidColors.orange)
                }
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(EduKidColors.orange)
                    .scaleEffect(1.15)
                    .padding(.top, EduKidSpacing.spacingSm)
            }
        }
    }
}
