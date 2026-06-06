import SwiftUI

struct EduKidPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(EduKidTypography.labelLarge)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [EduKidColors.orange, Color(red: 0.88, green: 0.49, blue: 0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: EduKidColors.orange.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct EduKidScreenBackground: View {
    var body: some View {
        EduKidColors.cream.ignoresSafeArea()
    }
}
