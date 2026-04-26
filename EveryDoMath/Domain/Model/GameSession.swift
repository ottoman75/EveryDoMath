import Foundation

// 게임 세션 클래스
final class GameSession: Identifiable, Codable, Hashable {
    let id: UUID
    let problems: [MathProblem]
    let grade: Grade
    let date: Date
    var userAnswers: [String?]          // nil = 미답(시간초과), "5/6", "3.8", "42" 등
    var timeTaken: TimeInterval
    var perProblemTimes: [TimeInterval]
    var score: Int
    var gameGrade: GameGrade
    var maxCombo: Int

    static let problemCount = 20

    var correctCount: Int {
        zip(problems, userAnswers).filter { problem, answer in
            guard let answer else { return false }
            return problem.isCorrectAnswer(answer)
        }.count
    }

    /// 맞힌 문제들의 평균 풀이 시간
    var averageCorrectTime: TimeInterval {
        let correctTimes = zip(problems, zip(userAnswers, perProblemTimes))
            .filter { problem, pair in
                guard let answer = pair.0 else { return false }
                return problem.isCorrectAnswer(answer)
            }
            .map { $0.1.1 }
        guard !correctTimes.isEmpty else { return .infinity }
        return correctTimes.reduce(0, +) / Double(correctTimes.count)
    }

    init(grade: Grade, problems: [MathProblem]) {
        self.id = UUID()
        self.problems = problems
        self.grade = grade
        self.date = Date()
        self.userAnswers = Array(repeating: nil, count: problems.count)
        self.timeTaken = 0
        self.perProblemTimes = Array(repeating: 0, count: problems.count)
        self.score = 0
        self.gameGrade = .D
        self.maxCombo = 0
    }

    // 기존 저장 데이터(maxCombo 없음) 호환
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        problems = try c.decode([MathProblem].self, forKey: .problems)
        grade = try c.decode(Grade.self, forKey: .grade)
        date = try c.decode(Date.self, forKey: .date)
        userAnswers = try c.decode([String?].self, forKey: .userAnswers)
        timeTaken = try c.decode(TimeInterval.self, forKey: .timeTaken)
        perProblemTimes = try c.decode([TimeInterval].self, forKey: .perProblemTimes)
        score = try c.decode(Int.self, forKey: .score)
        gameGrade = try c.decode(GameGrade.self, forKey: .gameGrade)
        maxCombo = try c.decodeIfPresent(Int.self, forKey: .maxCombo) ?? 0
    }

    /// 편의 팩토리: 학년에 맞는 새 세션 생성
    static func createNew(grade: Grade) -> GameSession {
        let problems = ProblemGenerator.generate(grade: grade)
        return GameSession(grade: grade, problems: problems)
    }

    // MARK: - Hashable
    static func == (lhs: GameSession, rhs: GameSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
