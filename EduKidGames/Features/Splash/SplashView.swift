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
            VStack(spacing: EduKidSpacing.spacingLg) {
                EduKidLogoHorizontal(height: 76, maxWidth: 300, showShadow: true)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(EduKidColors.orange)
                    .scaleEffect(1.15)
                    .padding(.top, EduKidSpacing.spacingSm)
            }
        }
    }
}
