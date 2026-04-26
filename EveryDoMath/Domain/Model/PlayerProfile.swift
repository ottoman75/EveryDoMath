import Foundation

// 플레이어 프로필 구조체
struct PlayerProfile: Codable, Identifiable {
    let id: UUID
    var nickname: String
    var preferredGrade: Grade
    var totalGamesPlayed: Int
    var bestScore: Int
    var createdAt: Date
    var totalXP: Int

    init(nickname: String, preferredGrade: Grade = .grade1) {
        self.id = UUID()
        self.nickname = nickname
        self.preferredGrade = preferredGrade
        self.totalGamesPlayed = 0
        self.bestScore = 0
        self.createdAt = Date()
        self.totalXP = 0
    }

    // 기존 저장 데이터(totalXP 없음) 호환을 위한 커스텀 디코더
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        nickname = try c.decode(String.self, forKey: .nickname)
        preferredGrade = try c.decode(Grade.self, forKey: .preferredGrade)
        totalGamesPlayed = try c.decode(Int.self, forKey: .totalGamesPlayed)
        bestScore = try c.decode(Int.self, forKey: .bestScore)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        totalXP = try c.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
    }
}
