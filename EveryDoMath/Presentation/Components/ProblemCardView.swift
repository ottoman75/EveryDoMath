import SwiftUI

struct ProblemCardView: View {
    let problemText: String

    var body: some View {
        Text(problemText)
            .font(.system(size: 52, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .foregroundColor(.appText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
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
    ProblemCardView(problemText: "12 + 34 = ?")
        .padding()
        .background(Color.appBackground)
}
