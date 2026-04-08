import SwiftUI

struct FeedbackOverlayView: View {
    let isCorrect: Bool
    let earnedScore: Int
    let correctAnswer: String

    @State private var appear = false

    var body: some View {
        ZStack {
            // 반투명 배경
            (isCorrect ? Color.appSuccess : Color.appDanger)
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 아이콘
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isCorrect ? .appSuccess : .appDanger)

                // 텍스트
                Text(isCorrect ? "정답!" : "오답!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)

                if isCorrect {
                    Text("+\(earnedScore)점")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSuccess)
                } else {
                    Text("정답: \(correctAnswer)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSubtext)
                }
            }
            .scaleEffect(appear ? 1.0 : 0.5)
            .opacity(appear ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                appear = true
            }
        }
    }
}

#Preview {
    FeedbackOverlayView(isCorrect: true, earnedScore: 35, correctAnswer: "42")
        .background(Color.appBackground)
}
