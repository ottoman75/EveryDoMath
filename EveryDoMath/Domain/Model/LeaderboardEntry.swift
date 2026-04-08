import Foundation

// 리더보드 항목 구조체
struct LeaderboardEntry: Identifiable, Codable {
    let id: UUID
    var rank: Int
    let playerName: String
    let score: Int
    let grade: Grade
    let gameGrade: GameGrade
    let date: Date

    init(playerName: String, score: Int, grade: Grade, gameGrade: GameGrade) {
        self.id = UUID()
        self.rank = 0
        self.playerName = playerName
        self.score = score
        self.grade = grade
        self.gameGrade = gameGrade
        self.date = Date()
    }
}
