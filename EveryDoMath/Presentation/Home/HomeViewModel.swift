import Foundation

@Observable
final class HomeViewModel {
    var selectedGrade: Grade = .grade1
    var profile: PlayerProfile?
    var currentStreak: Int = 0
    var todaySessionCount: Int = 0
    var todayBestScore: Int = 0
    var recentAchievements: [Achievement] = []
    var dailyChallenge: DailyChallenge = DailyChallenge.today()
    var goalProgress: GoalProgress?

    private let gameRepo = GameRepository()
    private let profileRepo = ProfileRepository()
    private let challengeRepo = DailyChallengeRepository()
    private let goalRepo = LearningGoalRepository()

    func loadData() {
        profile = profileRepo.loadProfile()
        selectedGrade = profile?.preferredGrade ?? .grade1

        let dailyRecords = profileRepo.loadDailyRecords()
        currentStreak = RewardManager.calculateStreak(dailyRecords: dailyRecords)

        let todayString = DailyRecord.todayString
        if let todayRecord = dailyRecords.first(where: { $0.dateString == todayString }) {
            todaySessionCount = todayRecord.sessionsPlayed
            todayBestScore = todayRecord.bestScore
        } else {
            todaySessionCount = 0
            todayBestScore = 0
        }

        let achievements = profileRepo.loadAchievements()
        recentAchievements = Array(achievements.sorted { $0.unlockedAt > $1.unlockedAt }.prefix(5))

        dailyChallenge = challengeRepo.loadChallenge()
        goalProgress = goalRepo.todayProgress(sessions: todaySessionCount)
    }

    func createNewSession() -> GameSession {
        let problems = ProblemGenerator.generate(grade: selectedGrade)
        return GameSession(grade: selectedGrade, problems: problems)
    }

    func updatePreferredGrade(_ grade: Grade) {
        selectedGrade = grade
        guard var p = profile else { return }
        p.preferredGrade = grade
        profileRepo.saveProfile(p)
        profile = p
    }
}
