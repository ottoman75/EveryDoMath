import SwiftUI

struct AchievementBadgeView: View {
    let title: String
    let iconName: String
    let isUnlocked: Bool
    var size: CGFloat = 72

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.appCardBorder, Color.appCardBorder], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: size, height: size)

                Image(systemName: iconName)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(isUnlocked ? .white : .appSubtext)
            }

            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isUnlocked ? .appText : .appSubtext)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: size + 8)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

#Preview {
    HStack(spacing: 20) {
        AchievementBadgeView(title: "첫 게임", iconName: "star.fill", isUnlocked: true)
        AchievementBadgeView(title: "만점왕", iconName: "crown.fill", isUnlocked: false)
    }
    .padding()
    .background(Color.appBackground)
}
