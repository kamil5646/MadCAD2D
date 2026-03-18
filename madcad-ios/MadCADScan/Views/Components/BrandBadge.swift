import SwiftUI

struct BrandBadge: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.09, green: 0.12, blue: 0.18),
                            Color(red: 0.05, green: 0.24, blue: 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            ZStack {
                RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                    .fill(Color(red: 0.86, green: 0.25, blue: 0.35))
                    .frame(width: size * 0.42, height: size * 0.42)
                    .offset(x: -size * 0.16, y: -size * 0.14)

                Text("M")
                    .font(.system(size: size * 0.26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(x: -size * 0.16, y: -size * 0.14)

                VStack(spacing: size * 0.06) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                            .fill(index == 1 ? Color.cyan.opacity(0.95) : Color.white.opacity(0.85))
                            .frame(width: size * (0.34 + CGFloat(index) * 0.08), height: size * 0.045)
                    }
                }
                .rotationEffect(.degrees(-28))
                .offset(x: size * 0.16, y: size * 0.14)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 10, y: 6)
        }
        .frame(width: size, height: size)
    }
}
