import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()
    @State private var showIAPStore = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
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

                    leaderboardButton
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showIAPStore) {
            IAPStoreView()
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

            GradeSelectorView(selectedGrade: Bindable(viewModel).selectedGrade) {
                showIAPStore = true
            }
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
            let grade = viewModel.selectedGrade
            if IAPManager.shared.isGradeUnlocked(grade) {
                let session = viewModel.createNewSession()
                appState.navigationPath.append(AppDestination.game(session))
            } else if TrialManager.isTrialAvailable(for: grade) {
                let session = viewModel.createTrialSession()
                TrialManager.markTrialUsed(for: grade)
                appState.navigationPath.append(AppDestination.game(session))
            } else {
                showIAPStore = true
            }
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
            appState.navigationPath.append(AppDestination.parentDashboard)
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

    private var leaderboardButton: some View {
        Button {
            appState.navigationPath.append(AppDestination.leaderboard)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18))
                Text("home.leaderboard")
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
}

// MARK: - StatCardView

private struct StatCardView: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
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
