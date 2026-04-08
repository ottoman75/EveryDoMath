import SwiftUI

struct ProfileSetupView: View {
    @Environment(AppState.self) private var appState
    @State private var nickname: String = ""
    @State private var selectedGrade: Grade = .grade3
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 앱 로고
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.appPrimaryStart, .appPrimaryEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .appPrimaryStart.opacity(0.5), radius: 20)

                        Text("∑")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("EveryDoMath")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.appPrimaryStart, .appPrimaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("매일 수학 챌린지")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.appSubtext)
                }

                // 닉네임 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("닉네임")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSubtext)

                    TextField("이름을 입력하세요", text: $nickname)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.appText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.appCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isFocused ? Color.appPrimaryStart : Color.appCardBorder, lineWidth: 1.5)
                                )
                        )
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 24)

                // 학년 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("학년")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSubtext)
                        .padding(.horizontal, 24)

                    GradeSelectorView(selectedGrade: $selectedGrade)
                }

                Spacer()

                // 시작 버튼
                Button {
                    saveAndStart()
                } label: {
                    Text("시작하기 →")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: nickname.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? [.appSubtext, .appSubtext]
                                    : [.appPrimaryStart, .appPrimaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(
                            color: nickname.trimmingCharacters(in: .whitespaces).isEmpty
                                ? .clear
                                : .appPrimaryStart.opacity(0.4),
                            radius: 12, y: 6
                        )
                }
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onTapGesture { isFocused = false }
    }

    private func saveAndStart() {
        let name = nickname.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let profile = PlayerProfile(nickname: name, preferredGrade: selectedGrade)
        let profileRepo = ProfileRepository()
        profileRepo.saveProfile(profile)

        appState.profile = profile
        // isFirstLaunch이 false가 되어 ContentView가 HomeView로 전환됨
    }
}

#Preview {
    ProfileSetupView()
        .environment(AppState())
}
