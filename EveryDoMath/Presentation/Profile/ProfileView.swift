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
                    profileHeader
                    statsSection
                    achievementsSection
                    resetButton
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("profile.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.loadData() }
        .alert("profile.reset_title", isPresented: $showResetAlert) {
            Button("profile.reset_cancel", role: .cancel) { }
            Button("profile.reset_confirm", role: .destructive) {
                viewModel.resetAllData()
                appState.navigationPath.removeLast(appState.navigationPath.count)
            }
        } message: {
            Text("profile.reset_message")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
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

                Text(verbatim: String(viewModel.profile?.nickname.prefix(1).uppercased() ?? "?"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            if viewModel.isEditingNickname {
                HStack(spacing: 8) {
                    TextField("profile.nickname_placeholder", text: $viewModel.nicknameInput)
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
                    Text(verbatim: viewModel.profile?.nickname ?? L("profile.default_player"))
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

            if let grade = viewModel.profile?.preferredGrade {
                Text(verbatim: grade.label)
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
                title: L("profile.total_play"),
                value: L("unit.times_count", viewModel.profile?.totalGamesPlayed ?? 0),
                icon: "gamecontroller.fill",
                color: .appPrimaryStart
            )
            profileStatCard(
                title: L("profile.best_score"),
                value: "\(viewModel.profile?.bestScore ?? 0)",
                icon: "trophy.fill",
                color: .appWarning
            )
            profileStatCard(
                title: L("profile.current_streak"),
                value: L("unit.days", viewModel.currentStreak),
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

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.achievements")
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
            Text("profile.reset_button")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.appDanger.opacity(0.7))
        }
        .padding(.top, 8)
    }
}
