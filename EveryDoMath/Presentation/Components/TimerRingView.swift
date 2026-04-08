import SwiftUI

struct TimerRingView: View {
    let totalTime: Double
    let remaining: Double

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return remaining / totalTime
    }

    private var ringColor: Color {
        if remaining > 15 { return .appSuccess }
        if remaining > 5 { return .appWarning }
        return .appDanger
    }

    private var isUrgent: Bool { remaining <= 5 && remaining > 0 }

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 배경 링
            Circle()
                .stroke(Color.appCardBorder, lineWidth: 8)

            // 프로그레스 링
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)

            // 남은 초 표시
            Text("\(Int(remaining))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(ringColor)
                .scaleEffect(pulseScale)
        }
        .onChange(of: isUrgent) { _, urgent in
            if urgent {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            } else {
                withAnimation(.default) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

#Preview {
    TimerRingView(totalTime: 30, remaining: 12)
        .frame(width: 120, height: 120)
        .padding()
        .background(Color.appBackground)
}
