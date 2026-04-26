import SwiftUI

struct FamilyLeaderboardView: View {
    @Bindable var viewModel: ParentDashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isInGroup, let group = viewModel.familyGroup {
                    groupCodeBanner(code: group.groupCode)
                    leaderboardList(group: group)

                    Button {
                        Task { await viewModel.leaveGroup() }
                    } label: {
                        Text("family.leave_group")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.appDanger)
                    }
                    .padding(.top, 8)

                } else {
                    joinOrCreateSection
                }

                if let error = viewModel.errorMessage {
                    Text(verbatim: error)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.appDanger)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
        }
    }

    // MARK: - 그룹 코드 배너

    private func groupCodeBanner(code: String) -> some View {
        VStack(spacing: 8) {
            Text("family.invite_code")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
            Text(verbatim: code)
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundColor(.appPrimaryStart)
                .kerning(4)
            Text("family.invite_hint")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.appSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appPrimaryStart.opacity(0.4), lineWidth: 1.5))
        )
    }

    // MARK: - 리더보드 목록

    private func leaderboardList(group: FamilyGroup) -> some View {
        VStack(spacing: 1) {
            ForEach(Array(group.sortedMembers.enumerated()), id: \.element.uid) { index, member in
                HStack(spacing: 14) {
                    rankBadge(rank: index + 1)

                    Text(verbatim: member.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.appText)

                    Spacer()

                    Text(verbatim: L("family.score_format", member.score))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.appWarning)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appCard)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appCardBorder, lineWidth: 1))
    }

    private func rankBadge(rank: Int) -> some View {
        ZStack {
            Circle()
                .fill(rankColor(rank).opacity(0.15))
                .frame(width: 36, height: 36)
            Text(verbatim: "\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(rankColor(rank))
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .appWarning
        case 2: return .appSubtext
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .appSubtext
        }
    }

    // MARK: - 그룹 참여/생성

    private var joinOrCreateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.appPrimaryStart.opacity(0.5))
                .padding(.bottom, 8)

            Text("family.join_prompt")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                TextField("family.code_placeholder", text: $viewModel.groupCodeInput)
                    .font(.system(size: 16, design: .monospaced))
                    .textCase(.uppercase)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appCard)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCardBorder, lineWidth: 1))
                    )

                Button {
                    Task { await viewModel.joinGroup() }
                } label: {
                    Text("family.join_button")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.appPrimaryStart)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.isLoading)
            }

            Text("family.or")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.appSubtext)

            Button {
                Task { await viewModel.createGroup() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("family.create_group")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.appPrimaryStart, .appPrimaryEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isLoading)

            if viewModel.isLoading {
                ProgressView()
                    .tint(.appPrimaryStart)
            }
        }
    }
}
