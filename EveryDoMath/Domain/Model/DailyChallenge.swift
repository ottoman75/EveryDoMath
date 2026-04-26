import Foundation

struct DailyChallenge: Codable, Identifiable {
    let id: String
    let type: ChallengeType
    var isCompleted: Bool
    var completedAt: Date?

    enum ChallengeType: String, Codable, CaseIterable {
        case speedRun
        case perfect
        case comboMaster
        case gradeHunter
        case consistency

        var title: String {
            switch self {
            case .speedRun:    return L("challenge.speedRun.title")
            case .perfect:     return L("challenge.perfect.title")
            case .comboMaster: return L("challenge.comboMaster.title")
            case .gradeHunter: return L("challenge.gradeHunter.title")
            case .consistency: return L("challenge.consistency.title")
            }
        }

        var description: String {
            switch self {
            case .speedRun:    return L("challenge.speedRun.desc")
            case .perfect:     return L("challenge.perfect.desc")
            case .comboMaster: return L("challenge.comboMaster.desc")
            case .gradeHunter: return L("challenge.gradeHunter.desc")
            case .consistency: return L("challenge.consistency.desc")
            }
        }

        var iconName: String {
            switch self {
            case .speedRun:    return "bolt.fill"
            case .perfect:     return "crown.fill"
            case .comboMaster: return "flame.fill"
            case .gradeHunter: return "star.fill"
            case .consistency: return "calendar.badge.checkmark"
            }
        }
    }

    static func today() -> DailyChallenge {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let month = calendar.component(.month, from: Date())
        let index = (day + month) % ChallengeType.allCases.count
        let type = ChallengeType.allCases[index]
        return DailyChallenge(id: dateString, type: type, isCompleted: false, completedAt: nil)
    }

    func isAchieved(by session: GameSession, totalTodaySessions: Int) -> Bool {
        switch type {
        case .speedRun:
            return session.timeTaken <= 60.0 && session.correctCount >= 15
        case .perfect:
            return session.correctCount == GameSession.problemCount
        case .comboMaster:
            var maxCombo = 0
            var current = 0
            for (problem, answer) in zip(session.problems, session.userAnswers) {
                if let answer, problem.isCorrectAnswer(answer) {
                    current += 1
                    maxCombo = max(maxCombo, current)
                } else {
                    current = 0
                }
            }
            return maxCombo >= 10
        case .gradeHunter:
            return session.gameGrade == .S
        case .consistency:
            return totalTodaySessions >= 3
        }
    }
}
