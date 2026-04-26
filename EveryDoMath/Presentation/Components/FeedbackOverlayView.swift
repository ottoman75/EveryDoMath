import SwiftUI

struct FeedbackOverlayView: View {
    let isCorrect: Bool
    let earnedScore: Int
    let correctAnswer: String

    @State private var appear = false

    var body: some View {
        ZStack {
            (isCorrect ? Color.appSuccess : Color.appDanger)
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isCorrect ? .appSuccess : .appDanger)

                Text(isCorrect ? "feedback.correct" : "feedback.wrong")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)

                if isCorrect {
                    Text(verbatim: L("feedback.score_earned", earnedScore))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSuccess)
                } else {
                    VStack(spacing: 6) {
                        Text("feedback.correct_answer_label")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.appSubtext)
                        Text(verbatim: correctAnswer)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.appWarning)
                    }
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
