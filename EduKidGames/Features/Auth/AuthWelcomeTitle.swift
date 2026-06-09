import SwiftUI

struct AuthWelcomeTitle: View {
    private let parts: [(String, Color)] = [
        ("H", Color(red: 1.0, green: 0.851, blue: 0.239)),
        ("o", EduKidColors.orange),
        ("ş", Color(red: 1.0, green: 0.42, blue: 0.616)),
        ("G", Color(red: 0.608, green: 0.365, blue: 0.898)),
        ("e", Color(red: 0.298, green: 0.788, blue: 0.941)),
        ("l", Color(red: 0.024, green: 0.839, blue: 0.627)),
        ("d", Color(red: 1.0, green: 0.851, blue: 0.239)),
        ("i", EduKidColors.orange),
        ("n", Color(red: 1.0, green: 0.42, blue: 0.616)),
        ("!", Color(red: 0.608, green: 0.365, blue: 0.898))
    ]

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index == 3 {
                    Spacer().frame(width: 6)
                }
                Text(part.0)
                    .font(EduKidTypography.headlineLarge)
                    .foregroundStyle(part.1)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityLabel("Hoş Geldin!")
    }
}
