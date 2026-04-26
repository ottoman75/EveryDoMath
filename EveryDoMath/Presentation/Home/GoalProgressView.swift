import SwiftUI

struct GoalProgressView: View {
    let progress: GoalProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("goal.progress.label", systemImage: "target")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.appText)
                Spacer()
                Text(verbatim: progress.progressText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(progress.isAchieved ? .appSuccess : .appSubtext)
                if progress.isAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appSuccess)
                        .font(.system(size: 16))
                }
            }

            ProgressView(value: progress.progressFraction)
                .tint(progress.isAchieved ? .appSuccess : .appPrimaryStart)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)

            if progress.isAchieved {
                Text("goal.progress.achieved")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.appSuccess)
            } else {
                let remaining = progress.goal.dailySessionTarget - progress.todaySessions
                Text(verbatim: L("goal.progress.remaining", remaining))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.appSubtext)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            progress.isAchieved ? Color.appSuccess.opacity(0.4) : Color.appCardBorder,
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 20)
    }
}
