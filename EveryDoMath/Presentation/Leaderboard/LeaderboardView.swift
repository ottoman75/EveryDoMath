import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                gradeFilter
                    .padding(.vertical, 12)

                if viewModel.isShowingRemote, let rank = viewModel.myRank {
                    myRankBanner(rank: rank)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isShowingRemote {
                    if viewModel.remoteEntries.isEmpty {
                        emptyState
                    } else {
                        remoteLeaderboardList
                    }
                } else {
                    if viewModel.localEntries.isEmpty {
                        emptyState
                    } else {
                        localLeaderboardList
                    }
                }
            }
        }
        .navigationTitle("leaderboard.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }

    // MARK: - Grade Filter

    private var gradeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: L("leaderboard.filter_all"), isSelected: viewModel.selectedGrade == nil) {
                    viewModel.filterByGrade(nil)
                }
                ForEach(Grade.allCases) { grade in
                    filterChip(title: grade.label, isSelected: viewModel.selectedGrade == grade) {
                        viewModel.filterByGrade(grade)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .appSubtext)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.appCard)
                    )
                )
        }
    }

    // MARK: - My Rank Banner

    private func myRankBanner(rank: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .foregroundColor(.appPrimaryEnd)
            Text("leaderboard.my_rank")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
            Spacer()
            Text(verbatim: L("leaderboard.rank_format", rank))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appPrimaryEnd)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appPrimaryEnd.opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.appWarning)
            Text(verbatim: message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.appSubtext)
            Spacer()
            Text("leaderboard.local_fallback")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.appSubtext.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.appCard))
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
                .tint(.appPrimaryEnd)
            Text("leaderboard.loading")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appSubtext)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.appSubtext)
            Text("leaderboard.empty")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
            Text("leaderboard.empty_hint")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appSubtext.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Remote Leaderboard

    private var remoteLeaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.remoteEntries) { entry in
                    remoteLeaderboardRow(entry: entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private func remoteLeaderboardRow(entry: RemoteLeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            rankBadge(rank: entry.rank)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(verbatim: entry.nickname)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(entry.isMe ? .appPrimaryEnd : .appText)
                    if entry.isMe {
                        Text("leaderboard.me_badge")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.appPrimaryEnd))
                    }
                }
                Text(verbatim: entry.grade.label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            Spacer()

            Text(verbatim: "\(entry.score)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text(verbatim: entry.gameGrade.rawValue)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(gradeColor(entry.gameGrade))
                .frame(width: 30, height: 30)
                .background(Circle().fill(gradeColor(entry.gameGrade).opacity(0.15)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(entry.isMe ? Color.appCard.opacity(0.8) : Color.appCard)
                .overlay(
                    entry.isMe
                        ? RoundedRectangle(cornerRadius: 14).stroke(Color.appPrimaryEnd.opacity(0.4), lineWidth: 1.5)
                        : nil
                )
        )
    }

    // MARK: - Local Leaderboard

    private var localLeaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.localEntries) { entry in
                    localLeaderboardRow(entry: entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private func localLeaderboardRow(entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            rankBadge(rank: entry.rank)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.playerName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appText)
                Text(verbatim: entry.grade.label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            Spacer()

            Text(verbatim: "\(entry.score)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text(verbatim: entry.gameGrade.rawValue)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(gradeColor(entry.gameGrade))
                .frame(width: 30, height: 30)
                .background(Circle().fill(gradeColor(entry.gameGrade).opacity(0.15)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))
    }

    // MARK: - Shared

    private func rankBadge(rank: Int) -> some View {
        ZStack {
            if rank <= 3 {
                Circle()
                    .fill(medalColor(rank: rank))
                    .frame(width: 36, height: 36)
                Text(verbatim: "\(rank)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text(verbatim: "\(rank)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appSubtext)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private func medalColor(rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return .appCardBorder
        }
    }

    private func gradeColor(_ grade: GameGrade) -> Color {
        switch grade {
        case .S: return .appWarning
        case .A: return .appSuccess
        case .B: return .appPrimaryStart
        case .C: return .appSubtext
        case .D: return .appDanger
        }
    }
}
