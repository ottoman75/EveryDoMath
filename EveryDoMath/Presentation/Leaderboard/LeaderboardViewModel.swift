import Foundation

@Observable
final class LeaderboardViewModel {
    var allEntries: [LeaderboardEntry] = []
    var entries: [LeaderboardEntry] = []
    var selectedGrade: Grade? = nil

    private let gameRepo = GameRepository()

    func loadEntries() {
        allEntries = gameRepo.getLeaderboard()
        filterByGrade(selectedGrade)
    }

    func filterByGrade(_ grade: Grade?) {
        selectedGrade = grade
        if let grade {
            entries = allEntries.filter { $0.grade == grade }
        } else {
            entries = allEntries
        }
        // 순위 재부여
        for i in 0..<entries.count {
            entries[i].rank = i + 1
        }
    }
}
