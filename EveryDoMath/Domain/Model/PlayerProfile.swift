import Foundation

// 플레이어 프로필 구조체
struct PlayerProfile: Codable, Identifiable {
    let id: UUID
    var nickname: String
    var preferredGrade: Grade
    var totalGamesPlayed: Int
    var bestScore: Int
    var createdAt: Date

    init(nickname: String, preferredGrade: Grade = .grade1) {
        self.id = UUID()
        self.nickname = nickname
        self.preferredGrade = preferredGrade
        self.totalGamesPlayed = 0
        self.bestScore = 0
        self.createdAt = Date()
    }
}
