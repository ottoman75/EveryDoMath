import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // 학년 필터
                gradeFilter
                    .padding(.vertical, 12)

                // 리더보드 리스트
                if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    leaderboardList
                }
            }
        }
        .navigationTitle("리더보드")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.loadEntries()
        }
    }

    // MARK: - Grade Filter

    private var gradeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "전체", isSelected: viewModel.selectedGrade == nil) {
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
            Text(title)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.appSubtext)
            Text("아직 기록이 없습니다")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
            Text("게임을 플레이하면 여기에 표시됩니다")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appSubtext.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.entries) { entry in
                    leaderboardRow(entry: entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private func leaderboardRow(entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            // 순위
            rankBadge(rank: entry.rank)

            // 플레이어 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appText)

                Text(entry.grade.label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            Spacer()

            // 점수
            Text("\(entry.score)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            // 등급 배지
            Text(entry.gameGrade.rawValue)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(gradeColor(entry.gameGrade))
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(gradeColor(entry.gameGrade).opacity(0.15))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard)
        )
    }

    private func rankBadge(rank: Int) -> some View {
        ZStack {
            if rank <= 3 {
                Circle()
                    .fill(medalColor(rank: rank))
                    .frame(width: 36, height: 36)

                Text("\(rank)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("\(rank)")
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
