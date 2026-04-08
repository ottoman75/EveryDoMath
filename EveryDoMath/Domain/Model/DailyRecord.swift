import Foundation

// 일일 기록 구조체 (스트릭 추적용)
struct DailyRecord: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String  // "yyyy-MM-dd"
    var sessionsPlayed: Int
    var bestScore: Int
    var streak: Int

    init(dateString: String, sessionsPlayed: Int = 1, bestScore: Int = 0, streak: Int = 1) {
        self.dateString = dateString
        self.sessionsPlayed = sessionsPlayed
        self.bestScore = bestScore
        self.streak = streak
    }

    static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
