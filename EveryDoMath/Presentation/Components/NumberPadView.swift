import SwiftUI

struct NumberPadView: View {
    @Binding var input: String
    let inputMode: InputMode
    let onSubmit: () -> Void

    private var rows: [[NumberPadButton]] {
        let specialKey: NumberPadButton
        switch inputMode {
        case .integer:  specialKey = .empty
        case .decimal:  specialKey = .special(".")
        case .fraction: specialKey = .special("/")
        }
        return [
            [.digit("1"), .digit("2"), .digit("3")],
            [.digit("4"), .digit("5"), .digit("6")],
            [.digit("7"), .digit("8"), .digit("9")],
            [specialKey,  .digit("0"), .delete]
        ]
    }

    var body: some View {
        VStack(spacing: 10) {
            if inputMode == .fraction {
                Text("numpad.fraction_hint")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.appSubtext)
            } else if inputMode == .decimal {
                Text("numpad.decimal_hint")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 10) {
                    ForEach(rows[rowIndex]) { button in
                        NumberPadButtonView(button: button) {
                            handleTap(button)
                        } onLongPress: {
                            if case .delete = button { input = "" }
                        }
                    }
                }
            }

            Button(action: onSubmit) {
                Text("numpad.confirm")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 16)
    }

    private func handleTap(_ button: NumberPadButton) {
        switch button {
        case .digit(let d):
            let maxLen: Int
            switch inputMode {
            case .integer:  maxLen = 7
            case .decimal:  maxLen = 8
            case .fraction: maxLen = 9
            }
            if input.count < maxLen { input += d }

        case .special(let s):
            if !input.contains(s) && !input.isEmpty {
                input += s
            }

        case .delete:
            if !input.isEmpty { input.removeLast() }

        case .empty:
            break
        }
    }
}

// MARK: - NumberPadButton

private enum NumberPadButton: Identifiable {
    case digit(String)
    case special(String)
    case delete
    case empty

    var id: String {
        switch self {
        case .digit(let d):   return "digit_\(d)"
        case .special(let s): return "special_\(s)"
        case .delete:         return "delete"
        case .empty:          return "empty"
        }
    }
}

// MARK: - NumberPadButtonView

private struct NumberPadButtonView: View {
    let button: NumberPadButton
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Group {
            switch button {
            case .digit(let d):
                padButton(label: d, isSymbol: false)

            case .special(let s):
                padButton(label: s, isSymbol: true)

            case .delete:
                Button(action: onTap) {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appSubtext)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in onLongPress() }
                )

            case .empty:
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
        }
    }

    private func padButton(label: String, isSymbol: Bool) -> some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: isSymbol ? 26 : 28, weight: .semibold, design: .rounded))
                .foregroundColor(isSymbol ? .appPrimaryEnd : .appText)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(isSymbol ? Color.appCard.opacity(0.6) : Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    isSymbol ? RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.appPrimaryEnd.opacity(0.5), lineWidth: 1.5) : nil
                )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NumberPadView(input: .constant("5/6"), inputMode: .fraction) {}
        NumberPadView(input: .constant("3.8"), inputMode: .decimal) {}
    }
    .background(Color.appBackground)
}
