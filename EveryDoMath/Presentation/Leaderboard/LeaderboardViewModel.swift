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

    var toastMessage: String?

    private let gameRepo = GameRepository()
    private let remoteRepo = RemoteLeaderboardRepository.shared
    private let moderationRepo = ModerationRepository.shared

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

    // MARK: - 신고 / 숨기기

    @MainActor
    func report(_ entry: RemoteLeaderboardEntry) async {
        do {
            try await moderationRepo.report(userId: entry.userId, nickname: entry.nickname)
            // 신고한 사용자는 바로 숨겨 준다. 다시 보고 싶지 않을 것이다.
            moderationRepo.block(userId: entry.userId)
            remoteEntries.removeAll { $0.userId == entry.userId }
            toastMessage = L("moderation.report_done")
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    @MainActor
    func block(_ entry: RemoteLeaderboardEntry) {
        moderationRepo.block(userId: entry.userId)
        remoteEntries.removeAll { $0.userId == entry.userId }
        toastMessage = L("moderation.block_done")
    }

    // MARK: - Private

    @MainActor
    private func fetchRemote(grade: Grade?) async {
        isLoading = true
        errorMessage = nil

        do {
            async let entriesTask = remoteRepo.fetchLeaderboard(grade: grade)
            async let rankTask = remoteRepo.fetchMyRank(grade: grade)

            // 숨긴 사용자는 목록에서 제외한다. 순위 번호는 서버가 매긴 값을
            // 그대로 쓴다(빈 자리가 생기는 편이 순위를 다시 매기는 것보다 정직하다).
            let blocked = moderationRepo.blockedUserIds
            remoteEntries = try await entriesTask.filter { !blocked.contains($0.userId) }
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
