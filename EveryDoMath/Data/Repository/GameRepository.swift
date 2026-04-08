import Foundation

// 게임 세션 및 리더보드 저장소 (UserDefaults + JSON)
final class GameRepository {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sessions = "game_sessions"
        static let leaderboard = "leaderboard"
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - 게임 세션

    func saveSession(_ session: GameSession) {
        var sessions = loadSessions()
        sessions.insert(session, at: 0)

        // 최근 100개만 유지
        if sessions.count > 100 {
            sessions = Array(sessions.prefix(100))
        }

        if let data = try? encoder.encode(sessions) {
            defaults.set(data, forKey: Keys.sessions)
        }
    }

    func loadSessions() -> [GameSession] {
        guard let data = defaults.data(forKey: Keys.sessions),
              let sessions = try? decoder.decode([GameSession].self, from: data) else {
            return []
        }
        return sessions
    }

    // MARK: - 리더보드

    func getLeaderboard() -> [LeaderboardEntry] {
        guard let data = defaults.data(forKey: Keys.leaderboard),
              let entries = try? decoder.decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return entries
    }

    func updateLeaderboard(with entry: LeaderboardEntry) {
        var entries = getLeaderboard()
        entries.append(entry)

        // 점수 내림차순 정렬 후 최대 50개 유지
        entries.sort { $0.score > $1.score }
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }

        // 순위 재부여
        for i in 0..<entries.count {
            entries[i].rank = i + 1
        }

        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: Keys.leaderboard)
        }
    }
}
