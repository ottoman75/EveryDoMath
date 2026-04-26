import Foundation

@Observable
final class LeaderboardViewModel {
    // 원격 데이터
    var remoteEntries: [RemoteLeaderboardEntry] = []
    var myRank: Int? = nil

    // 로컬 폴백 데이터
    var localEntries: [LeaderboardEntry] = []

    var selectedGrade: Grade? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    /// 원격 로드 성공 여부에 따라 표시할 데이터 소스
    var isShowingRemote: Bool = false

    private let gameRepo = GameRepository()
    private let remoteRepo = RemoteLeaderboardRepository.shared

    func loadEntries() {
        // 로컬은 항상 로드 (오프라인 폴백)
        localEntries = gameRepo.getLeaderboard()

        Task {
            await fetchRemote(grade: selectedGrade)
        }
    }

    func filterByGrade(_ grade: Grade?) {
        selectedGrade = grade
        Task {
            await fetchRemote(grade: grade)
        }
    }

    func refresh() {
        Task {
            await fetchRemote(grade: selectedGrade)
        }
    }

    // MARK: - Private

    @MainActor
    private func fetchRemote(grade: Grade?) async {
        isLoading = true
        errorMessage = nil

        do {
            async let entriesTask = remoteRepo.fetchLeaderboard(grade: grade)
            async let rankTask = remoteRepo.fetchMyRank(grade: grade)

            remoteEntries = try await entriesTask
            myRank = await rankTask
            isShowingRemote = true
        } catch {
            errorMessage = error.localizedDescription
            isShowingRemote = false
            print("❌ [LeaderboardViewModel] 원격 조회 실패: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
