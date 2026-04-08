import SwiftUI

struct ResultView: View {
    let session: GameSession
    @State private var viewModel: ResultViewModel
    @Environment(AppState.self) private var appState

    @State private var displayedScore: Int = 0
    @State private var showContent = false

    init(session: GameSession) {
        self.session = session
        _viewModel = State(initialValue: ResultViewModel(session: session))
    }

    var body: some View {
        ZStack {
            // 그라데이션 배경
            LinearGradient(
                colors: [.appPrimaryStart, .appPrimaryEnd, .appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)

                    // 등급 배지
                    gradeBadge

                    // 점수
                    scoreSection

                    // 통계
                    statsSection

                    // 신규 업적
                    if !viewModel.newAchievements.isEmpty {
                        newAchievementsSection
                    }

                    // 버튼들
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.processResult()
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
            animateScore()
        }
    }

    // MARK: - Grade Badge

    private var gradeBadge: some View {
        ZStack {
            Circle()
                .fill(gradeColor.opacity(0.2))
                .frame(width: 120, height: 120)

            Circle()
                .stroke(gradeColor, lineWidth: 4)
                .frame(width: 120, height: 120)

            Text(viewModel.gameGrade.rawValue)
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundColor(gradeColor)
        }
        .scaleEffect(showContent ? 1.0 : 0.3)
        .opacity(showContent ? 1.0 : 0.0)
    }

    private var gradeColor: Color {
        switch viewModel.gameGrade {
        case .S: return .appWarning
        case .A: return .appSuccess
        case .B: return .appPrimaryStart
        case .C: return .appSubtext
        case .D: return .appDanger
        }
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 8) {
            Text("\(displayedScore)")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text("점")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)

            if viewModel.isNewBestScore {
                Text("NEW BEST!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appWarning)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color.appWarning.opacity(0.2))
                    )
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            resultStatView(title: "정답", value: "\(viewModel.correctCount)/\(GameSession.problemCount)", color: .appSuccess)
            resultStatView(title: "시간", value: String(format: "%.1f초", viewModel.totalTime), color: .appPrimaryStart)
            resultStatView(title: "콤보", value: "\(session.score > 0 ? "x\(viewModel.correctCount)" : "-")", color: .appWarning)
        }
    }

    private func resultStatView(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(0.8))
        )
    }

    // MARK: - New Achievements

    private var newAchievementsSection: some View {
        VStack(spacing: 12) {
            Text("새로운 업적!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appWarning)

            HStack(spacing: 16) {
                ForEach(viewModel.newAchievements) { achievement in
                    AchievementBadgeView(
                        title: achievement.type.title,
                        iconName: achievement.type.iconName,
                        isUnlocked: true,
                        size: 56
                    )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard.opacity(0.8))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 리더보드
            Button {
                appState.navigationPath.append(AppDestination.leaderboard)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                    Text("리더보드 보기")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appCard)
                )
            }

            // 다시 하기
            Button {
                // 현재 result을 pop하고 새 게임 시작
                appState.navigationPath.removeLast()
                let newSession = GameSession.createNew(grade: session.grade)
                appState.navigationPath.append(AppDestination.game(newSession))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("다시 하기")
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.appPrimaryStart, .appPrimaryEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // 홈으로
            Button {
                appState.navigationPath.removeLast(appState.navigationPath.count)
            } label: {
                Text("홈으로")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.appSubtext)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Score Animation

    private func animateScore() {
        let target = viewModel.finalScore
        guard target > 0 else { return }

        let steps = 30
        let interval = 1.0 / Double(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                displayedScore = Int(Double(target) * (Double(i) / Double(steps)))
            }
        }
    }
}
