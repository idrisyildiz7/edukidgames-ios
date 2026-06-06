import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            EduKidColors.cream.ignoresSafeArea()
            VStack(spacing: EduKidSpacing.spacingMd) {
                EduKidAstronautLogo(size: 180)
                VStack(spacing: 6) {
                    Text("EduKid")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(EduKidColors.navy)
                    Text("Games")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
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
