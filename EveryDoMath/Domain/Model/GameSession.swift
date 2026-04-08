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
