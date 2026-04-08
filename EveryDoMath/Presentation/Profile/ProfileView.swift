import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(AppState.self) private var appState
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 프로필 헤더
                    profileHeader

                    // 통계 카드
                    statsSection

                    // 업적 섹션
                    achievementsSection

                    // 초기화 버튼
                    resetButton
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.loadData() }
        .alert("모든 데이터 초기화", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("초기화", role: .destructive) {
                viewModel.resetAllData()
                appState.navigationPath.removeLast(appState.navigationPath.count)
            }
        } message: {
            Text("모든 게임 기록, 업적, 프로필이 삭제됩니다. 이 작업은 취소할 수 없습니다.")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // 아바타
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(String(viewModel.profile?.nickname.prefix(1).uppercased() ?? "?"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // 닉네임
            if viewModel.isEditingNickname {
                HStack(spacing: 8) {
                    TextField("닉네임", text: $viewModel.nicknameInput)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        viewModel.saveNickname()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appSuccess)
                    }
                }
                .padding(.horizontal, 40)
            } else {
                HStack(spacing: 8) {
                    Text(viewModel.profile?.nickname ?? "플레이어")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)

                    Button {
                        viewModel.isEditingNickname = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.appSubtext)
                    }
                }
            }

            // 학년 표시
            if let grade = viewModel.profile?.preferredGrade {
                Text(grade.label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .leading, endPoint: .trailing))
                    )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            profileStatCard(
                title: "총 플레이",
                value: "\(viewModel.profile?.totalGamesPlayed ?? 0)회",
                icon: "gamecontroller.fill",
                color: .appPrimaryStart
            )
            profileStatCard(
                title: "최고 점수",
                value: "\(viewModel.profile?.bestScore ?? 0)",
                icon: "trophy.fill",
                color: .appWarning
            )
            profileStatCard(
                title: "현재 스트릭",
                value: "\(viewModel.currentStreak)일",
                icon: "flame.fill",
                color: .appDanger
            )
        }
        .padding(.horizontal, 16)
    }

    private func profileStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
            Text(title)
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

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("업적")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
                .padding(.horizontal, 16)

            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.allAchievementTypes, id: \.self) { type in
                    let unlocked = viewModel.isUnlocked(type)
                    AchievementBadgeView(
                        title: type.title,
                        iconName: type.iconName,
                        isUnlocked: unlocked,
                        size: 56
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            showResetAlert = true
        } label: {
            Text("데이터 초기화")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.appDanger.opacity(0.7))
        }
        .padding(.top, 8)
    }
}
