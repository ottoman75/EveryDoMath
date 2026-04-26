import SwiftUI

struct ShareCardView: View {
    let session: GameSession
    let grade: GameGrade
    let nickname: String

    private let cardWidth: CGFloat = 360
    private let cardHeight: CGFloat = 480
    private let cardCornerRadius: CGFloat = 24
    private let badgeSize: CGFloat = 100

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "sum")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("EveryDoMath")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text(verbatim: formattedDate)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: badgeSize, height: badgeSize)
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 3)
                        .frame(width: badgeSize, height: badgeSize)
                    Text(grade.rawValue)
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                Text(verbatim: "\(session.score)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 12)

                Text("result.points_unit")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                HStack(spacing: 0) {
                    statItem(value: "\(session.correctCount)/\(GameSession.problemCount)", labelKey: "sharecard.correct_label")
                    Divider()
                        .frame(height: 36)
                        .background(.white.opacity(0.3))
                    statItem(value: String(format: "%.1fs", session.timeTaken), labelKey: "sharecard.time_label")
                    Divider()
                        .frame(height: 36)
                        .background(.white.opacity(0.3))
                    statItem(value: session.grade.label, labelKey: "sharecard.grade_label")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.white.opacity(0.1))

                HStack {
                    Text(verbatim: "@\(nickname)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("sharecard.hashtag")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
    }

    // MARK: - Stat Item

    private func statItem(value: String, labelKey: String) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var gradientColors: [Color] {
        switch grade {
        case .S:
            return [Color(red: 1.0, green: 0.75, blue: 0.0), Color(red: 1.0, green: 0.45, blue: 0.0)]
        case .A:
            return [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.0, green: 0.55, blue: 0.3)]
        case .B:
            return [Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.35, blue: 0.85)]
        case .C:
            return [Color(red: 0.6, green: 0.6, blue: 0.7), Color(red: 0.4, green: 0.4, blue: 0.5)]
        case .D:
            return [Color(red: 0.9, green: 0.35, blue: 0.35), Color(red: 0.7, green: 0.15, blue: 0.15)]
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
}
