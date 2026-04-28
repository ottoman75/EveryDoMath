import SwiftUI

/// 수식 문자열을 파싱해 분수는 세로(가로선) 형태로, 나머지는 텍스트로 렌더링
/// - "2/9 − 1/3 = ?" → 실제 분수 기호 형태로 표시
/// - "11 − 8 = ?" → 일반 텍스트 유지
struct MathExpressionView: View {
    let expression: String
    var fontSize: CGFloat

    init(_ expression: String, fontSize: CGFloat = 32) {
        self.expression = expression
        self.fontSize = fontSize
    }

    // MARK: - Token

    private struct Token: Identifiable {
        let id: Int
        let kind: Kind

        enum Kind {
            case fraction(num: String, den: String)
            case plain(String)
        }
    }

    private var tokens: [Token] {
        expression.components(separatedBy: " ").enumerated().map { idx, part in
            let slices = part.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            if slices.count == 2,
               !slices[0].isEmpty, !slices[1].isEmpty,
               Int(slices[0]) != nil, Int(slices[1]) != nil {
                return Token(id: idx, kind: .fraction(num: String(slices[0]), den: String(slices[1])))
            }
            return Token(id: idx, kind: .plain(part))
        }
    }

    private var hasFraction: Bool {
        tokens.contains { token in
            if case .fraction = token.kind { return true }
            return false
        }
    }

    // MARK: - Body

    var body: some View {
        if hasFraction {
            HStack(alignment: .center, spacing: fontSize * 0.4) {
                ForEach(tokens) { token in
                    tokenView(token)
                }
            }
        } else {
            Text(expression)
                .font(.system(size: fontSize * 1.6, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundColor(.appText)
        }
    }

    @ViewBuilder
    private func tokenView(_ token: Token) -> some View {
        switch token.kind {
        case .fraction(let num, let den):
            VStack(spacing: fontSize * 0.1) {
                Text(num)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                Rectangle()
                    .frame(height: max(2, fontSize * 0.07))
                    .padding(.horizontal, 1)
                Text(den)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
            }
            .foregroundColor(.appText)
            .fixedSize()

        case .plain(let value):
            Text(value)
                .font(.system(size: fontSize * 1.15, weight: .bold, design: .rounded))
                .foregroundColor(.appText)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        MathExpressionView("2/9 − 1/3 = ?", fontSize: 32)
        MathExpressionView("3/4 × 2/5 = ?", fontSize: 32)
        MathExpressionView("1/8 + 3/8 = ?", fontSize: 32)
        MathExpressionView("11 − 8 = ?", fontSize: 32)
        MathExpressionView("1/6", fontSize: 44)
    }
    .padding()
    .background(Color.appBackground)
}
