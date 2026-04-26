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
            LinearGradient(
                colors: [.appPrimaryStart, .appPrimaryEnd, .appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)

                    gradeBadge

                    scoreSection

                    statsSection

                    xpSection

                    if !viewModel.newAchievements.isEmpty {
                        newAchievementsSection
                    }

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
            Text(verbatim: "\(displayedScore)")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text("result.points_unit")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)

            if viewModel.isNewBestScore {
                Text("result.new_best")
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
            resultStatView(title: L("result.stat_correct"), value: "\(viewModel.correctCount)/\(GameSession.problemCount)", color: .appSuccess)
            resultStatView(title: L("result.stat_time"), value: String(format: "%.1fs", viewModel.totalTime), color: .appPrimaryStart)
            resultStatView(title: L("result.stat_combo"), value: "\(session.score > 0 ? "x\(viewModel.correctCount)" : "-")", color: .appWarning)
        }
    }

    private func resultStatView(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text(verbatim: title)
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

    // MARK: - XP Section

    private var xpSection: some View {
        VStack(spacing: 10) {
            // 레벨업 배너
            if viewModel.didLevelUp {
                HStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 20))
                    Text(verbatim: L("result.level_up", viewModel.levelAfter))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.appWarning)
                }
                .padding(.vertical, 6)
            }

            HStack {
                Text(verbatim: L("result.xp_earned", viewModel.earnedXP))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.appWarning)
                Spacer()
                Text(verbatim: L("result.level_label", viewModel.levelAfter))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            // XP 진행 바
            let totalXP = viewModel.currentTotalXP
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appCardBorder)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [.appPrimaryStart, .appWarning],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(XPSystem.progress(for: totalXP)), height: 10)
                        .animation(.easeOut(duration: 0.8), value: viewModel.earnedXP)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCard.opacity(0.8)))
    }

    // MARK: - New Achievements

    private var newAchievementsSection: some View {
        VStack(spacing: 12) {
            Text("result.new_achievements")
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
            Button {
                viewModel.shareResult(nickname: appState.profile?.nickname ?? L("profile.default_player"))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("result.share")
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

            Button {
                appState.navigationPath.append(AppDestination.leaderboard)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                    Text("result.leaderboard")
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

            Button {
                appState.navigationPath.removeLast()
                let newSession = GameSession.createNew(grade: session.grade)
                appState.navigationPath.append(AppDestination.game(newSession))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("result.play_again")
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

            Button {
                appState.navigationPath.removeLast(appState.navigationPath.count)
            } label: {
                Text("result.go_home")
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
