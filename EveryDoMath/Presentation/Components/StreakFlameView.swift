import SwiftUI

struct StreakFlameView: View {
    let streak: Int

    @State private var flicker = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appWarning, .appDanger],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(flicker ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: flicker
                )

            Text("\(streak)일 연속")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
        )
        .onAppear {
            flicker = true
        }
    }
}

#Preview {
    StreakFlameView(streak: 7)
        .padding()
        .background(Color.appBackground)
}
