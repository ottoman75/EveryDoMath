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
    private let familyRepo = FamilyGroupRepository()

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
        // 공개된 것부터 지운다.
        //
        // 로컬만 지우면 "모든 게임 기록, 업적, 프로필이 삭제됩니다" 가 거짓이
        // 된다. 별명과 점수는 글로벌 리더보드와(참여했다면) 가족 그룹 문서에
        // 올라가 다른 사람에게 계속 보이기 때문이다.
        RemoteLeaderboardRepository.shared.deleteMyEntry()

        if let groupId = familyRepo.savedGroupId,
           let uid = UserIdentityRepository.shared.userId {
            // 로컬 키를 먼저 끊으면 실패했을 때 탈퇴할 방법이 사라진다.
            // 성공한 뒤에 savedGroupId 를 비우는 것은 leaveGroup 이 한다.
            Task { try? await familyRepo.leaveGroup(groupId: groupId, uid: uid) }
        }

        UserDefaults.standard.removeObject(forKey: "player_profile")
        UserDefaults.standard.removeObject(forKey: "game_sessions")
        UserDefaults.standard.removeObject(forKey: "daily_records")
        UserDefaults.standard.removeObject(forKey: "achievements")
        UserDefaults.standard.removeObject(forKey: "leaderboard")
    }
}
