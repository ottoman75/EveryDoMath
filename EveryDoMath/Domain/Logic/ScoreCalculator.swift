import Foundation

// 점수 계산 로직
// 최대 1000점 = baseScore(500) + timeBonus(300) + comboBonus(200)
struct ScoreCalculator {

    /// 최종 점수 계산
    static func calculate(session: GameSession, maxCombo: Int) -> Int {
        let base = baseScore(correctCount: session.correctCount)
        let time = timeBonus(session: session)
        let combo = comboBonus(maxCombo: maxCombo)
        return base + time + combo
    }

    /// baseScore = correctCount / 20 * 500 (최대 500)
    static func baseScore(correctCount: Int) -> Int {
        return correctCount * 500 / GameSession.problemCount
    }

    /// timeBonus: 맞힌 문제의 평균 풀이 시간 기반 (최대 300)
    static func timeBonus(session: GameSession) -> Int {
        let avgTime = session.averageCorrectTime

        // 맞힌 문제가 없으면 보너스 없음
        if session.correctCount == 0 { return 0 }

        if avgTime <= 3.0 { return 300 }
        if avgTime <= 5.0 { return 250 }
        if avgTime <= 8.0 { return 200 }
        if avgTime <= 12.0 { return 150 }
        if avgTime <= 20.0 { return 100 }
        if avgTime <= 30.0 { return 50 }
        return 0
    }

    /// comboBonus = min(maxCombo * 10, 200) (최대 200)
    static func comboBonus(maxCombo: Int) -> Int {
        return min(maxCombo * 10, 200)
    }

    /// 등급 산출
    static func grade(for score: Int) -> GameGrade {
        GameGrade.from(score: score)
    }
}
