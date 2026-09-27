import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()
    @State private var showParentGate = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                // 간격 18 — 24 로 두면 콘텐츠가 한 화면을 넘어 하단
                // 리더보드 버튼이 잘린다(6.9" 기준).
                VStack(spacing: 18) {
                    headerSection

                    if viewModel.currentStreak > 0 {
                        StreakFlameView(streak: viewModel.currentStreak)
                    }

                    DailyChallengeCardView(
                        challenge: viewModel.dailyChallenge,
                        todaySessionCount: viewModel.todaySessionCount
                    )
                    .padding(.horizontal, 20)

                    if let progress = viewModel.goalProgress, progress.goal.dailySessionTarget > 0 {
                        GoalProgressView(progress: progress)
                    }

                    gradeSection

                    todayRecordSection

                    if !viewModel.recentAchievements.isEmpty {
                        recentAchievementsSection
                    }

                    startButton

                    parentDashboardButton

                    leaderboardRow
                }
                .padding(.vertical, 12)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showParentGate) {
            ParentGateView {
                appState.navigationPath.append(AppDestination.parentDashboard)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: appState.navigationPath.count) { _, count in
            if count == 0 {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("app.title")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let profile = viewModel.profile {
                    HStack(spacing: 8) {
                        Text(verbatim: L("home.greeting", profile.nickname))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.appSubtext)

                        Text(verbatim: L("home.level_badge", XPSystem.level(for: profile.totalXP)))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [.appPrimaryStart, .appPrimaryEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                    }
                }
            }

            Spacer()

            Button {
                appState.navigationPath.append(AppDestination.profile)
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Grade Selection

    private var gradeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.grade_section")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
                .padding(.horizontal, 20)

            GradeSelectorView(selectedGrade: Bindable(viewModel).selectedGrade)
        }
    }

    // MARK: - Today Record

    private var todayRecordSection: some View {
        HStack(spacing: 16) {
            StatCardView(
                title: L("home.today_play"),
                value: L("unit.times_count", viewModel.todaySessionCount),
                iconName: "gamecontroller.fill",
                color: .appPrimaryStart
            )

            StatCardView(
                title: L("home.best_score"),
                value: "\(viewModel.profile?.bestScore ?? 0)",
                iconName: "trophy.fill",
                color: .appWarning
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Recent Achievements

    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.recent_achievements")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentAchievements) { achievement in
                        AchievementBadgeView(
                            title: achievement.type.title,
                            iconName: achievement.type.iconName,
                            isUnlocked: true,
                            size: 56
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            let session = viewModel.createNewSession()
            appState.navigationPath.append(AppDestination.game(session))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 22))
                Text("home.start_button")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                LinearGradient(
                    colors: [.appPrimaryStart, .appPrimaryEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .appPrimaryStart.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Parent Dashboard Button

    private var parentDashboardButton: some View {
        Button {
            // 부모 게이트를 통과해야 들어간다. 아이가 학습 목표와 알림을
            // 마음대로 끄는 것을 막는다.
            showParentGate = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 18))
                Text("home.parent_dashboard")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.appSubtext)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Leaderboard Button

    /// 리더보드 두 종류는 성격이 같으므로 한 줄에 나란히 둔다.
    /// 세로로 쌓으면 홈 하단 버튼이 4개가 되어 빽빽해진다.
    private var leaderboardRow: some View {
        HStack(spacing: 12) {
            secondaryButton(titleKey: "home.leaderboard", icon: "chart.bar.fill") {
                appState.navigationPath.append(AppDestination.leaderboard)
            }
            secondaryButton(titleKey: "home.family_leaderboard", icon: "person.3.fill") {
                appState.navigationPath.append(AppDestination.familyLeaderboard)
            }
        }
        .padding(.horizontal, 20)
    }

    private func secondaryButton(titleKey: LocalizedStringKey, icon: String,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(titleKey)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.appSubtext)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appCard)
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.appCardBorder, lineWidth: 1))
            )
        }
    }

}

// MARK: - StatCardView

private struct StatCardView: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(verbatim: value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text(verbatim: title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
    }
}
