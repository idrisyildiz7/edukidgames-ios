import SwiftUI

struct EduKidLogoHorizontal: View {
    var height: CGFloat = 44

    var body: some View {
        Image("LogoHorizontal")
            .resizable()
            .scaledToFit()
            .frame(height: height)
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
