import SwiftUI

struct ParentDashboardView: View {
    @State private var viewModel = ParentDashboardViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                tabPicker
                    .padding(.vertical, 12)

                TabView(selection: $viewModel.selectedTab) {
                    learningStatsTab.tag(0)
                    FamilyLeaderboardView(viewModel: viewModel).tag(1)
                    GoalSettingsView(goal: Bindable(viewModel).goal) { newGoal in
                        viewModel.saveGoal(newGoal)
                    }.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    appState.navigationPath.removeLast()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.appText)
                }
            }
        }
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("parent.title")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
            Text("parent.subtitle")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appSubtext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        let tabs: [(String, Int)] = [
            (L("parent.tab.stats"), 0),
            (L("parent.tab.family"), 1),
            (L("parent.tab.goal"), 2)
        ]
        return HStack(spacing: 0) {
            ForEach(tabs, id: \.1) { title, tag in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tag
                    }
                } label: {
                    Text(verbatim: title)
                        .font(.system(size: 14, weight: viewModel.selectedTab == tag ? .bold : .medium, design: .rounded))
                        .foregroundColor(viewModel.selectedTab == tag ? .appPrimaryStart : .appSubtext)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            if viewModel.selectedTab == tag {
                                Rectangle()
                                    .fill(Color.appPrimaryStart)
                                    .frame(height: 2)
                            }
                        }
                }
            }
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.appCardBorder).frame(height: 1)
        }
    }

    // MARK: - 학습 현황 탭

    private var learningStatsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCards
                    .padding(.horizontal, 20)

                weeklyChart
                    .padding(.horizontal, 20)

                if !viewModel.operationAccuracy.isEmpty {
                    accuracySection
                        .padding(.horizontal, 20)
                }

                if let progress = viewModel.todayProgress {
                    GoalProgressView(progress: progress)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            dashCard(title: L("parent.card.total_games"), value: L("unit.times_count", viewModel.totalGames), icon: "gamecontroller.fill", color: .appPrimaryStart)
            dashCard(title: L("parent.card.best_score"), value: "\(viewModel.bestScore)", icon: "trophy.fill", color: .appWarning)
            dashCard(title: L("parent.card.streak"), value: L("unit.days", viewModel.currentStreak), icon: "flame.fill", color: .appDanger)
        }
    }

    private func dashCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(verbatim: value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
            Text(verbatim: title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appCardBorder, lineWidth: 1))
        )
    }

    // MARK: - 주간 차트

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("parent.chart.title")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            HStack(alignment: .bottom, spacing: 8) {
                let maxCount = max(viewModel.weeklyStats.map { $0.count }.max() ?? 1, 1)
                let todayLabel = L("parent.chart.today")
                ForEach(viewModel.weeklyStats, id: \.day) { stat in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(stat.day == todayLabel ? Color.appPrimaryStart : Color.appPrimaryStart.opacity(0.4))
                            .frame(height: CGFloat(stat.count) / CGFloat(maxCount) * 60 + 4)
                        Text(verbatim: stat.day)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.appSubtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appCardBorder, lineWidth: 1))
        )
    }

    // MARK: - 연산 정확도

    private var accuracySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("parent.accuracy.title")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            ForEach(viewModel.operationAccuracy, id: \.op) { item in
                HStack(spacing: 10) {
                    Text(verbatim: item.op)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.appPrimaryStart)
                        .frame(width: 28)

                    ProgressView(value: item.accuracy)
                        .tint(item.accuracy >= 0.8 ? .appSuccess : item.accuracy >= 0.5 ? .appWarning : .appDanger)
                        .scaleEffect(x: 1, y: 1.4, anchor: .center)

                    Text(verbatim: String(format: "%.0f%%", item.accuracy * 100))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appCardBorder, lineWidth: 1))
        )
    }
}
