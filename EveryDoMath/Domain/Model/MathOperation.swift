import Foundation

// 사칙연산 열거형
enum MathOperation: String, Codable, CaseIterable {
    case addition
    case subtraction
    case multiplication
    case division

    var symbol: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "−"
        case .multiplication: return "×"
        case .division: return "÷"
        }
    }
}
