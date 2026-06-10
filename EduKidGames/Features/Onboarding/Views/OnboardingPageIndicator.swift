import SwiftUI

struct OnboardingPageIndicator: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage
                            ? LinearGradient(
                                colors: [EduKidColors.orange, EduKidColors.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [EduKidColors.outline, EduKidColors.outline],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                    )
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.72), value: currentPage)
            }
        }
    }
}
