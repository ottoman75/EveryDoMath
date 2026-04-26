import Foundation

// 오늘의 도전 저장소 (UserDefaults + JSON)
final class DailyChallengeRepository {
    private let defaults = UserDefaults.standard
    private let key = "daily_challenge"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadChallenge() -> DailyChallenge {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        if let data = defaults.data(forKey: key),
           let saved = try? decoder.decode(DailyChallenge.self, from: data),
           saved.id == today {
            return saved
        }

        // 오늘 챌린지가 없으면 새로 생성
        let fresh = DailyChallenge.today()
        save(fresh)
        return fresh
    }

    func save(_ challenge: DailyChallenge) {
        if let data = try? encoder.encode(challenge) {
            defaults.set(data, forKey: key)
        }
    }

    func markCompleted() {
        var challenge = loadChallenge()
        challenge.isCompleted = true
        challenge.completedAt = Date()
        save(challenge)
    }
}
