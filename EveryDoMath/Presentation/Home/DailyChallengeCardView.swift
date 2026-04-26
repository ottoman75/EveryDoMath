import SwiftUI

struct DailyChallengeCardView: View {
    let challenge: DailyChallenge
    var todaySessionCount: Int = 0
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            if !challenge.isCompleted { onTap?() }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(challenge.isCompleted ? 0.3 : 0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : challenge.type.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(challenge.isCompleted ? .appSuccess : iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("challenge.header")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.appSubtext)
                        Spacer()
                        if challenge.isCompleted {
                            Text("challenge.completed")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.appSuccess)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.appSuccess.opacity(0.15)))
                        } else if let badge = progressBadge {
                            Text(verbatim: badge)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(iconColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(iconColor.opacity(0.12)))
                        }
                    }
                    Text(verbatim: challenge.type.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                    Text(verbatim: challenge.type.description)
                        .font(.system(size: 13, design: .rounded))
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
                                challenge.isCompleted ? Color.appSuccess.opacity(0.4) : iconColor.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(challenge.isCompleted ? 0.85 : 1.0)
    }

    private var progressBadge: String? {
        guard case .consistency = challenge.type, !challenge.isCompleted, todaySessionCount > 0 else { return nil }
        return L("challenge.progress_badge", todaySessionCount)
    }

    private var iconColor: Color {
        switch challenge.type {
        case .speedRun:    return .appWarning
        case .perfect:     return .appSuccess
        case .comboMaster: return .appDanger
        case .gradeHunter: return .appPrimaryStart
        case .consistency: return .appSubtext
        }
    }
}
