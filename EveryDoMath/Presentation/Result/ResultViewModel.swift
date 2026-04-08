import Foundation

@Observable
final class ResultViewModel {
    var session: GameSession
    var finalScore: Int = 0
    var gameGrade: GameGrade = .D
    var correctCount: Int = 0
    var totalTime: TimeInterval = 0
    var newAchievements: [Achievement] = []
    var isNewBestScore: Bool = false

    private let gameRepo = GameRepository()
    private let profileRepo = ProfileRepository()

    init(session: GameSession) {
        self.session = session
    }

    func processResult() {
        finalScore = session.score
        gameGrade = session.gameGrade
        correctCount = session.correctCount
        totalTime = session.timeTaken

        // 세션 저장
        gameRepo.saveSession(session)

        // 리더보드 갱신
        if let profile = profileRepo.loadProfile() {
            let entry = LeaderboardEntry(
                playerName: profile.nickname,
                score: finalScore,
                grade: session.grade,
                gameGrade: gameGrade
            )
            gameRepo.updateLeaderboard(with: entry)

            // 프로필 업데이트
            var updatedProfile = profile
            updatedProfile.totalGamesPlayed += 1
            if finalScore > updatedProfile.bestScore {
                updatedProfile.bestScore = finalScore
                isNewBestScore = true
            }
            profileRepo.saveProfile(updatedProfile)

            // 스트릭 갱신
            let streak = profileRepo.updateStreak()
            profileRepo.updateDailyBestScore(finalScore)

            // 업적 체크
            let existingAchievements = profileRepo.loadAchievements()
            let newOnes = RewardManager.checkNewAchievements(
                session: session,
                profile: updatedProfile,
                currentStreak: streak,
                existingAchievements: existingAchievements
            )
            if !newOnes.isEmpty {
                profileRepo.saveAchievements(existingAchievements + newOnes)
                newAchievements = newOnes
            }
        }
    }
}
