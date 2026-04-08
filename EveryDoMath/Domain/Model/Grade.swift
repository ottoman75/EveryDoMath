import Foundation

// 학년 열거형 (1~6학년)
enum Grade: Int, Codable, CaseIterable, Identifiable, Hashable {
    case grade1 = 1, grade2, grade3, grade4, grade5, grade6

    var id: Int { rawValue }
    var label: String { "\(rawValue)학년" }

    /// 해당 학년에서 허용되는 연산 목록
    var allowedOperations: [MathOperation] {
        switch self {
        case .grade1, .grade2:
            return [.addition, .subtraction]
        case .grade3:
            return [.addition, .subtraction, .multiplication]
        case .grade4, .grade5, .grade6:
            return [.addition, .subtraction, .multiplication, .division]
        }
    }
}
