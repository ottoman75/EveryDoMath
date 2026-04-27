import Foundation

@Observable
final class GameViewModel {
    var session: GameSession
    var currentProblemIndex: Int = 0
    var currentInput: String = ""
    var remainingTime: Double = 30.0
    var showFeedback: Bool = false
    var lastAnswerCorrect: Bool = false
    var earnedScore: Int = 0
    var comboCount: Int = 0
    var maxCombo: Int = 0
    var isGameFinished: Bool = false

    private var timer: Timer?
    private var problemStartTime: Date = Date()
    private var totalElapsed: TimeInterval = 0
    private let totalTime: Double = 30.0

    init(session: GameSession) {
        self.session = session
    }

    var currentProblem: MathProblem? {
        guard currentProblemIndex < session.problems.count else { return nil }
        return session.problems[currentProblemIndex]
    }

    var currentInputMode: InputMode {
        currentProblem?.inputMode ?? .integer
    }

    func startGame() {
        startProblemTimer()
    }

    func submitAnswer() {
        guard !showFeedback, !isGameFinished else { return }
        guard !currentInput.isEmpty else { return }

        // 분수/소수 모드: 형식 최소 검증
        switch currentInputMode {
        case .integer:
            guard Int(currentInput) != nil else { return }
        case .decimal:
            guard Double(currentInput) != nil else { return }
        case .fraction:
            let parts = currentInput.split(separator: "/")
            guard parts.count <= 2,
                  parts.allSatisfy({ Int($0) != nil }),
                  !currentInput.hasSuffix("/") else { return }
        }

        processAnswer(currentInput)
    }

    func appendDigit(_ d: String) {
        guard !showFeedback else { return }
        let maxLen: Int
        switch currentInputMode {
        case .integer:  maxLen = 7
        case .decimal:  maxLen = 8
        case .fraction: maxLen = 9  // "99/999"
        }
        if currentInput.count < maxLen {
            currentInput += d
        }
    }

    func deleteLastDigit() {
        guard !currentInput.isEmpty else { return }
        currentInput.removeLast()
    }

    func skipCurrentProblem() {
        processTimeout()
    }

    // MARK: - Private

    private func startProblemTimer() {
        timer?.invalidate()
        remainingTime = totalTime
        problemStartTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingTime -= 0.1
            if self.remainingTime <= 0 {
                self.remainingTime = 0
                self.processTimeout()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func processAnswer(_ answer: String) {
        stopTimer()

        let elapsed = Date().timeIntervalSince(problemStartTime)
        guard let problem = currentProblem else { return }
        let isCorrect = problem.isCorrectAnswer(answer)

        session.userAnswers[currentProblemIndex] = answer
        session.perProblemTimes[currentProblemIndex] = elapsed
        totalElapsed += elapsed

        if isCorrect {
            comboCount += 1
            maxCombo = max(maxCombo, comboCount)
            earnedScore = 100 + max(0, Int((totalTime - elapsed) * 2))
        } else {
            comboCount = 0
            earnedScore = 0
        }

        lastAnswerCorrect = isCorrect
        showFeedback = true
        currentInput = ""

        // 오답/타임아웃은 정답을 읽을 수 있도록 1.5초, 정답은 0.8초
        let delay = isCorrect ? 0.8 : 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.advanceToNext()
        }
    }

    private func processTimeout() {
        stopTimer()
        guard currentProblemIndex < session.userAnswers.count else { return }

        session.userAnswers[currentProblemIndex] = nil
        session.perProblemTimes[currentProblemIndex] = totalTime
        totalElapsed += totalTime

        comboCount = 0
        earnedScore = 0
        lastAnswerCorrect = false
        showFeedback = true
        currentInput = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.advanceToNext()
        }
    }

    private func advanceToNext() {
        showFeedback = false
        if currentProblemIndex + 1 >= session.problems.count {
            finishGame()
        } else {
            currentProblemIndex += 1
            startProblemTimer()
        }
    }

    private func finishGame() {
        session.timeTaken = totalElapsed
        session.maxCombo = maxCombo
        let finalScore = ScoreCalculator.calculate(session: session, maxCombo: maxCombo)
        session.score = finalScore
        session.gameGrade = GameGrade.from(score: finalScore)
        isGameFinished = true
    }
}
