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
        let trimmed = nicknameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
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
        for grade in Grade.allCases where !grade.isFree {
            UserDefaults.standard.removeObject(forKey: "trial_used_grade_\(grade.rawValue)")
        }
    }
}
