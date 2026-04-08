import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 상단: 앱 타이틀 + 프로필 버튼
                    headerSection

                    // 스트릭 섹션
                    if viewModel.currentStreak > 0 {
                        StreakFlameView(streak: viewModel.currentStreak)
                    }

                    // 학년 선택
                    gradeSection

                    // 오늘 기록
                    todayRecordSection

                    // 최근 업적
                    if !viewModel.recentAchievements.isEmpty {
                        recentAchievementsSection
                    }

                    // 시작하기 버튼
                    startButton

                    // 리더보드 버튼
                    leaderboardButton
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("EveryDoMath")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let profile = viewModel.profile {
                    Text("안녕, \(profile.nickname)!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.appSubtext)
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
            Text("학년 선택")
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
                title: "오늘 플레이",
                value: "\(viewModel.todaySessionCount)회",
                iconName: "gamecontroller.fill",
                color: .appPrimaryStart
            )

            StatCardView(
                title: "최고 점수",
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
            Text("최근 업적")
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
                Text("시작하기")
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

    // MARK: - Leaderboard Button

    private var leaderboardButton: some View {
        Button {
            appState.navigationPath.append(AppDestination.leaderboard)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18))
                Text("리더보드")
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

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text(title)
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
