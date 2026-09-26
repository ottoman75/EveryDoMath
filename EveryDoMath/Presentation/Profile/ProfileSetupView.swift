import SwiftUI

struct ProfileSetupView: View {
    @Environment(AppState.self) private var appState
    @State private var nickname: String = ""
    @State private var selectedGrade: Grade = .grade3
    @State private var validationError: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

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

                    Text("app.title")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.appPrimaryStart, .appPrimaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("app.tagline")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.appSubtext)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("setup.nickname_label")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSubtext)

                    TextField("setup.nickname_placeholder", text: $nickname)
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
                        .onChange(of: nickname) { _, _ in validationError = nil }

                    // 별명은 다른 사용자에게 공개된다. 실명을 적지 않도록 안내한다.
                    Text(validationError.map { LocalizedStringKey($0) } ?? "nickname.hint")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(validationError == nil ? .appSubtext : .appDanger)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("setup.grade_label")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.appSubtext)
                        .padding(.horizontal, 24)

                    GradeSelectorView(selectedGrade: $selectedGrade)
                }

                Spacer()

                Button {
                    saveAndStart()
                } label: {
                    Text("setup.start_button")
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
        let name: String
        switch NicknameValidator.validate(nickname) {
        case .success(let valid):
            name = valid
        case .failure(let failure):
            validationError = failure.messageKey
            return
        }

        let profile = PlayerProfile(nickname: name, preferredGrade: selectedGrade)
        let profileRepo = ProfileRepository()
        profileRepo.saveProfile(profile)

        appState.profile = profile
    }
}

#Preview {
    ProfileSetupView()
        .environment(AppState())
}
