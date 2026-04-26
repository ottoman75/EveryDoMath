import Foundation

enum Grade: Int, Codable, CaseIterable, Identifiable, Hashable {
    case grade1 = 1, grade2, grade3, grade4, grade5, grade6

    var id: Int { rawValue }
    var label: String { L("grade.label", rawValue) }
    var isFree: Bool { self == .grade1 || self == .grade2 }

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
