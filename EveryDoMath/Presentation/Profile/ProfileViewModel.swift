import Foundation

@Observable
final class ProfileViewModel {
    var profile: PlayerProfile?
    var achievements: [Achievement] = []
    var allAchievementTypes: [AchievementType] = AchievementType.allCases
    var dailyRecords: [DailyRecord] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var isEditingNickname: Bool = false
    var nicknameInput: String = ""
    var nicknameError: String?

    private let profileRepo = ProfileRepository()
    private let gameRepo = GameRepository()

    func loadData() {
        profile = profileRepo.loadProfile()
        nicknameInput = profile?.nickname ?? ""
        achievements = profileRepo.loadAchievements()
        dailyRecords = profileRepo.loadDailyRecords()
        currentStreak = RewardManager.calculateStreak(dailyRecords: dailyRecords)
        longestStreak = dailyRecords.map { $0.streak }.max() ?? 0
    }

    func saveNickname() {
        let trimmed: String
        switch NicknameValidator.validate(nicknameInput) {
        case .success(let valid):
            trimmed = valid
        case .failure(let failure):
            nicknameError = failure.messageKey
            return
        }
        nicknameError = nil
        var p = profile ?? PlayerProfile(nickname: trimmed)
        p.nickname = trimmed
        profileRepo.saveProfile(p)
        profile = p
        isEditingNickname = false
    }

    func isUnlocked(_ type: AchievementType) -> Bool {
        achievements.contains { $0.type == type }
    }

    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "player_profile")
        UserDefaults.standard.removeObject(forKey: "game_sessions")
        UserDefaults.standard.removeObject(forKey: "daily_records")
        UserDefaults.standard.removeObject(forKey: "achievements")
        UserDefaults.standard.removeObject(forKey: "leaderboard")
    }
}
