import Foundation

// 프로필, 업적, 일일기록 저장소 (UserDefaults + JSON)
final class ProfileRepository {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let profile = "player_profile"
        static let achievements = "achievements"
        static let dailyRecords = "daily_records"
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - 프로필

    func saveProfile(_ profile: PlayerProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: Keys.profile)
        }
    }

    func loadProfile() -> PlayerProfile? {
        guard let data = defaults.data(forKey: Keys.profile),
              let profile = try? decoder.decode(PlayerProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    // MARK: - 업적

    func saveAchievements(_ achievements: [Achievement]) {
        if let data = try? encoder.encode(achievements) {
            defaults.set(data, forKey: Keys.achievements)
        }
    }

    func loadAchievements() -> [Achievement] {
        guard let data = defaults.data(forKey: Keys.achievements),
              let achievements = try? decoder.decode([Achievement].self, from: data) else {
            return []
        }
        return achievements
    }

    // MARK: - 일일 기록

    func saveDailyRecords(_ records: [DailyRecord]) {
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: Keys.dailyRecords)
        }
    }

    func loadDailyRecords() -> [DailyRecord] {
        guard let data = defaults.data(forKey: Keys.dailyRecords),
              let records = try? decoder.decode([DailyRecord].self, from: data) else {
            return []
        }
        return records
    }

    /// 오늘 플레이 기록 갱신 후 스트릭 반환
    func updateStreak() -> Int {
        var records = loadDailyRecords()
        let todayString = DailyRecord.todayString

        if let index = records.firstIndex(where: { $0.dateString == todayString }) {
            records[index].sessionsPlayed += 1
        } else {
            let newRecord = DailyRecord(dateString: todayString)
            records.append(newRecord)
        }

        let streak = RewardManager.calculateStreak(dailyRecords: records)

        // 오늘 기록에 스트릭 값 갱신
        if let index = records.firstIndex(where: { $0.dateString == todayString }) {
            records[index].streak = streak
        }

        saveDailyRecords(records)
        return streak
    }

    /// 오늘 기록의 최고 점수 갱신
    func updateDailyBestScore(_ score: Int) {
        var records = loadDailyRecords()
        let todayString = DailyRecord.todayString

        if let index = records.firstIndex(where: { $0.dateString == todayString }) {
            if score > records[index].bestScore {
                records[index].bestScore = score
            }
        }

        saveDailyRecords(records)
    }
}
