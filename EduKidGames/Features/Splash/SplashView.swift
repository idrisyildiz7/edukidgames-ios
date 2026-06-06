import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            EduKidColors.cream.ignoresSafeArea()
            VStack(spacing: EduKidSpacing.spacingLg) {
                EduKidAstronautLogo(size: 220)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(EduKidColors.orange)
                    .scaleEffect(1.2)
            }
        }
    }
}
