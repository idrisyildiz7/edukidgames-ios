import SwiftUI

struct EduKidLogoHorizontal: View {
    var height: CGFloat = 44
    var maxWidth: CGFloat? = nil
    var showShadow: Bool = false

    var body: some View {
        Image("LogoHorizontal")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
            .frame(height: height)
            .shadow(
                color: showShadow ? Color(red: 1.0, green: 0.62, blue: 0.11).opacity(0.22) : .clear,
                radius: showShadow ? 12 : 0,
                x: 0,
                y: showShadow ? 6 : 0
            )
            .accessibilityLabel("EduKid Games")
    }
}

struct EduKidAstronautLogo: View {
    var size: CGFloat = 200

    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("EduKid Games")
    }
}
