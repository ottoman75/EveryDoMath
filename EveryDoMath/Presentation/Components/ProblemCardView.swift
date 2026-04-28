import SwiftUI

struct ProblemCardView: View {
    let problemText: String

    var body: some View {
        MathExpressionView(problemText, fontSize: 32)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .scale(scale: 0.8)).combined(with: .opacity)
            ))
    }
}

#Preview {
    VStack(spacing: 16) {
        ProblemCardView(problemText: "2/9 − 1/3 = ?")
        ProblemCardView(problemText: "3/4 × 2/5 = ?")
        ProblemCardView(problemText: "12 + 34 = ?")
    }
    .padding()
    .background(Color.appBackground)
}
