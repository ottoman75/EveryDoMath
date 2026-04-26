import Foundation
import SwiftUI

@Observable
final class ResultViewModel {
    var session: GameSession
    var finalScore: Int = 0
    var gameGrade: GameGrade = .D
    var correctCount: Int = 0
    var totalTime: TimeInterval = 0
    var newAchievements: [Achievement] = []
    var isNewBestScore: Bool = false
    var earnedXP: Int = 0
    var didLevelUp: Bool = false
    var levelBefore: Int = 1
    var levelAfter: Int = 1
    var currentTotalXP: Int = 0

    private let gameRepo = GameRepository()
    private let profileRepo = ProfileRepository()
    private let challengeRepo = DailyChallengeRepository()
    private let familyRepo = FamilyGroupRepository()
    private let userIdentityRepo = UserIdentityRepository.shared

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

            // 서버 리더보드 업로드 (비동기, 실패해도 무관)
            RemoteLeaderboardRepository.shared.uploadScore(
                nickname: profile.nickname,
                grade: session.grade,
                score: finalScore,
                gameGrade: gameGrade,
                correctCount: session.correctCount
            )

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

            // XP 계산 및 저장
            let xp = XPSystem.xpEarned(
                correctCount: session.correctCount,
                maxCombo: session.maxCombo,
                gameGrade: gameGrade
            )
            earnedXP = xp
            levelBefore = XPSystem.level(for: updatedProfile.totalXP)
            updatedProfile.totalXP += xp
            levelAfter = XPSystem.level(for: updatedProfile.totalXP)
            currentTotalXP = updatedProfile.totalXP
            didLevelUp = levelAfter > levelBefore

            // 스트릭 알림 업데이트
            NotificationManager.shared.scheduleStreakReminder(streak: streak)

            // 오늘의 도전 달성 체크
            checkDailyChallenge()

            // 가족 그룹 점수 업데이트 (비동기)
            if let groupId = familyRepo.savedGroupId {
                Task {
                    try? await familyRepo.updateScore(
                        groupId: groupId,
                        uid: userIdentityRepo.userId,
                        score: finalScore
                    )
                }
            }
        }
    }

    private func checkDailyChallenge() {
        let challenge = challengeRepo.loadChallenge()
        guard !challenge.isCompleted else { return }
        let records = profileRepo.loadDailyRecords()
        let todaySessions = records.first(where: { $0.dateString == DailyRecord.todayString })?.sessionsPlayed ?? 0
        if challenge.isAchieved(by: session, totalTodaySessions: todaySessions) {
            challengeRepo.markCompleted()
        }
    }

    @MainActor
    func shareResult(nickname: String) {
        let card = ShareCardView(session: session, grade: gameGrade, nickname: nickname)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }
        let text = L("result.share_text", gameGrade.rawValue, finalScore)
        presentShareSheet(items: [image, text])
    }
}
