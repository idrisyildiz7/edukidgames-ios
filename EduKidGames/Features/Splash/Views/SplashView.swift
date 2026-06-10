import SwiftUI

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [EduKidColors.gradientTop, EduKidColors.cream, EduKidColors.gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SplashBackgroundBlobs()

            VStack(spacing: EduKidSpacing.spacingLg) {
                EduKidLogoHorizontal(height: 76, maxWidth: 300, showShadow: true)
                    .scaleEffect(pulse ? 1.02 : 0.98)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                SplashLoadingDots()
                    .padding(.top, EduKidSpacing.spacingSm)
            }
        }
        .onAppear { pulse = true }
    }
}

private struct SplashBackgroundBlobs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(EduKidColors.orange.opacity(0.14))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: -180)
            Circle()
                .fill(Color(red: 0.18, green: 0.77, blue: 0.71).opacity(0.12))
                .frame(width: 160, height: 160)
                .offset(x: -130, y: 220)
            Circle()
                .fill(Color(red: 1.0, green: 0.45, blue: 0.55).opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: 100, y: 280)
        }
        .allowsHitTesting(false)
    }
}

private struct SplashLoadingDots: View {
    private let colors: [Color] = [
        EduKidColors.orange,
        Color(red: 0.18, green: 0.77, blue: 0.71),
        Color(red: 1.0, green: 0.45, blue: 0.55)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = sin(t * 4 + Double(index) * 0.85)
                    Circle()
                        .fill(colors[index])
                        .frame(width: 11, height: 11)
                        .offset(y: CGFloat(phase) * 5)
                        .opacity(0.55 + (phase + 1) * 0.225)
                }
            }
        }
    }
}
