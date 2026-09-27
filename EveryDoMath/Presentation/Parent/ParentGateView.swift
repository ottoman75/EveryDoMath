import SwiftUI

/// 부모 게이트.
///
/// 부모 대시보드는 학습 목표와 알림을 끌 수 있고 가족 그룹 탈퇴도 가능하다.
/// 아이가 마음대로 들어가면 안 된다.
///
/// 주의: 이 앱은 수학 앱이라 아이가 앱 내 문제 수준은 전부 푼다. 그래서
/// 숫자를 한글로 적어 **읽기 능력**을 요구하고, 두 자리 곱셈으로 난이도를
/// 앱 최고 학년(6학년 분수·소수)보다 위에 둔다.
struct ParentGateView: View {
    let onPass: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var question = Question.make()
    @State private var input = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool

    struct Question {
        let a: Int, b: Int
        var answer: Int { a * b }
        var text: String { "\(Self.korean(a)) 곱하기 \(Self.korean(b))" }

        static func make() -> Question {
            Question(a: Int.random(in: 11...19), b: Int.random(in: 11...19))
        }

        /// 11~19 를 한글로. 아이가 숫자만 보고 계산하지 못하게 한다.
        static func korean(_ n: Int) -> String {
            let ones = ["", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"]
            guard n >= 10, n < 20 else { return "\(n)" }
            let r = n % 10
            return r == 0 ? "십" : "십\(ones[r])"
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 8) {
                    Text("gate.title")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                    Text("gate.subtitle")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.appSubtext)
                        .multilineTextAlignment(.center)
                }

                Text(verbatim: question.text)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18).fill(Color.appCard)
                            .overlay(RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.appCardBorder, lineWidth: 1)))

                TextField("gate.placeholder", text: $input)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                    .focused($isFocused)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(Color.appCard)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(showError ? Color.appDanger : Color.appCardBorder, lineWidth: 1.5)))
                    .onChange(of: input) { _, _ in showError = false }

                Text(showError ? "gate.wrong" : "gate.hint")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(showError ? .appDanger : .appSubtext)

                Button {
                    submit()
                } label: {
                    Text("gate.confirm")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd],
                                           startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(input.isEmpty)
                .opacity(input.isEmpty ? 0.5 : 1)

                Button("gate.cancel") { dismiss() }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.appSubtext)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear { isFocused = true }
    }

    private func submit() {
        guard Int(input.trimmingCharacters(in: .whitespaces)) == question.answer else {
            // 틀리면 새 문제로 바꿔 반복 시도를 어렵게 한다
            showError = true
            input = ""
            question = Question.make()
            return
        }
        dismiss()
        onPass()
    }
}

#Preview {
    ParentGateView(onPass: {})
}
