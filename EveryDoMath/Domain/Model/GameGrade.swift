import Foundation

// 게임 등급 열거형 (S/A/B/C/D)
enum GameGrade: String, Codable, CaseIterable, Comparable {
    case S, A, B, C, D

    var minScore: Int {
        switch self {
        case .S: return 950
        case .A: return 850
        case .B: return 700
        case .C: return 500
        case .D: return 0
        }
    }

    var displayColor: String {
        switch self {
        case .S: return "gradeS"
        case .A: return "gradeA"
        case .B: return "gradeB"
        case .C: return "gradeC"
        case .D: return "gradeD"
        }
    }

    static func from(score: Int) -> GameGrade {
        if score >= GameGrade.S.minScore { return .S }
        if score >= GameGrade.A.minScore { return .A }
        if score >= GameGrade.B.minScore { return .B }
        if score >= GameGrade.C.minScore { return .C }
        return .D
    }

    static func < (lhs: GameGrade, rhs: GameGrade) -> Bool {
        lhs.minScore < rhs.minScore
    }
}
