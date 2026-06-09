import SwiftUI

struct AuthLoginBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.984, blue: 0.961),
                    EduKidColors.cream,
                    Color(red: 1.0, green: 0.957, blue: 0.902)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(EduKidColors.orange.opacity(0.14))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: -180)
            Circle()
                .fill(EduKidColors.teal.opacity(0.12))
                .frame(width: 160, height: 160)
                .offset(x: -130, y: 220)
            Circle()
                .fill(Color(red: 1.0, green: 0.42, blue: 0.616).opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: 100, y: 280)
        }
        .allowsHitTesting(false)
    }
}

struct AuthInputField: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(EduKidColors.navy)

            HStack(spacing: 0) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(EduKidColors.onSurfaceVariant)
                    .frame(width: 46)

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                }
                .font(EduKidTypography.bodyMedium)
                .foregroundStyle(EduKidColors.navy)
                .padding(.vertical, 13)
                .padding(.trailing, 14)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(EduKidColors.outline, lineWidth: 1.5)
            )
        }
    }
}
