import Foundation

struct XPSystem {
    // 레벨 N 진입에 필요한 누적 XP = N * (N-1) * 25
    // Lv1: 0, Lv2: 50, Lv3: 150, Lv4: 300, Lv5: 500 ...
    static let maxLevel = 50

    static func xpRequired(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (level - 1) * level * 25
    }

    static func level(for totalXP: Int) -> Int {
        var lv = 1
        while lv < maxLevel && xpRequired(for: lv + 1) <= totalXP {
            lv += 1
        }
        return lv
    }

    static func xpInCurrentLevel(totalXP: Int) -> Int {
        let lv = level(for: totalXP)
        return totalXP - xpRequired(for: lv)
    }

    static func xpNeededForCurrentLevel(totalXP: Int) -> Int {
        let lv = level(for: totalXP)
        if lv >= maxLevel { return 1 }
        return xpRequired(for: lv + 1) - xpRequired(for: lv)
    }

    static func progress(for totalXP: Int) -> Double {
        let lv = level(for: totalXP)
        if lv >= maxLevel { return 1.0 }
        let current = Double(xpInCurrentLevel(totalXP: totalXP))
        let needed = Double(xpNeededForCurrentLevel(totalXP: totalXP))
        return needed > 0 ? min(current / needed, 1.0) : 1.0
    }

    static func xpEarned(correctCount: Int, maxCombo: Int, gameGrade: GameGrade) -> Int {
        let baseXP = correctCount * 10
        let comboBonus = max(0, maxCombo - 1) * 3
        let gradeBonus: Int
        switch gameGrade {
        case .S: gradeBonus = 50
        case .A: gradeBonus = 30
        case .B: gradeBonus = 15
        case .C: gradeBonus = 5
        case .D: gradeBonus = 0
        }
        return baseXP + comboBonus + gradeBonus
    }
}
