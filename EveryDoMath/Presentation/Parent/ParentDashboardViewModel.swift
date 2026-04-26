import Foundation

@Observable
final class ParentDashboardViewModel {
    var selectedTab: Int = 0

    // 학습 현황
    var weeklyStats: [(day: String, count: Int)] = []
    var operationAccuracy: [(op: String, accuracy: Double)] = []
    var totalGames: Int = 0
    var bestScore: Int = 0
    var currentStreak: Int = 0

    // 가족 리더보드
    var familyGroup: FamilyGroup?
    var isInGroup: Bool = false
    var groupCodeInput: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    // 학습 목표
    var goal: LearningGoal = .default
    var todayProgress: GoalProgress?

    private let profileRepo = ProfileRepository()
    private let gameRepo = GameRepository()
    private let goalRepo = LearningGoalRepository()
    private let familyRepo = FamilyGroupRepository()
    private let userIdentityRepo = UserIdentityRepository.shared

    func loadData() {
        loadLearningStats()
        loadGoal()
        Task { await loadFamilyGroup() }
    }

    // MARK: - 학습 현황

    private func loadLearningStats() {
        let profile = profileRepo.loadProfile()
        totalGames = profile?.totalGamesPlayed ?? 0
        bestScore = profile?.bestScore ?? 0

        let records = profileRepo.loadDailyRecords()
        currentStreak = RewardManager.calculateStreak(dailyRecords: records)

        // 최근 7일 일일 플레이 횟수
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        weeklyStats = (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let dateStr = dateFormatter.string(from: date)
            let count = records.first(where: { $0.dateString == dateStr })?.sessionsPlayed ?? 0
            let dayLabel = daysAgo == 0 ? L("parent.chart.today") : L("parent.chart.days_ago", daysAgo)
            return (day: dayLabel, count: count)
        }

        // 오늘 플레이 횟수로 목표 진행도 계산
        let todaySessions = records.first(where: {
            $0.dateString == DailyRecord.todayString
        })?.sessionsPlayed ?? 0
        todayProgress = goalRepo.todayProgress(sessions: todaySessions)

        // 연산 정확도 (최근 세션들 기반)
        let sessions = gameRepo.loadSessions()
        let recentSessions = Array(sessions.suffix(50))
        computeOperationAccuracy(from: recentSessions)
    }

    private func computeOperationAccuracy(from sessions: [GameSession]) {
        var correct: [String: Int] = [:]
        var total: [String: Int] = [:]

        for session in sessions {
            for (problem, answer) in zip(session.problems, session.userAnswers) {
                let op = problem.operation.symbol
                total[op, default: 0] += 1
                if let a = answer, problem.isCorrectAnswer(a) {
                    correct[op, default: 0] += 1
                }
            }
        }

        operationAccuracy = MathOperation.allCases.compactMap { op in
            let t = total[op.symbol] ?? 0
            guard t > 0 else { return nil }
            let accuracy = Double(correct[op.symbol] ?? 0) / Double(t)
            return (op: op.symbol, accuracy: accuracy)
        }
    }

    // MARK: - 가족 그룹

    @MainActor
    func loadFamilyGroup() async {
        guard let groupId = familyRepo.savedGroupId else { return }
        isLoading = true
        do {
            familyGroup = try await familyRepo.fetchLeaderboard(groupId: groupId)
            isInGroup = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func createGroup() async {
        isLoading = true
        errorMessage = nil
        do {
            let uid = userIdentityRepo.userId
            let nickname = profileRepo.loadProfile()?.nickname ?? L("family.default_nickname")
            familyGroup = try await familyRepo.createGroup(uid: uid, nickname: nickname)
            isInGroup = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func joinGroup() async {
        let code = groupCodeInput.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 6 else {
            errorMessage = L("family.code_error")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let uid = userIdentityRepo.userId
            let nickname = profileRepo.loadProfile()?.nickname ?? L("family.default_nickname")
            familyGroup = try await familyRepo.joinGroup(code: code, uid: uid, nickname: nickname)
            isInGroup = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func leaveGroup() async {
        guard let groupId = familyRepo.savedGroupId else { return }
        isLoading = true
        do {
            let uid = userIdentityRepo.userId
            try await familyRepo.leaveGroup(groupId: groupId, uid: uid)
            familyGroup = nil
            isInGroup = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 학습 목표

    func loadGoal() {
        goal = goalRepo.load()
    }

    func saveGoal(_ newGoal: LearningGoal) {
        goal = newGoal
        goalRepo.save(newGoal)
        // 진행도 다시 계산
        let records = profileRepo.loadDailyRecords()
        let todaySessions = records.first(where: {
            $0.dateString == DailyRecord.todayString
        })?.sessionsPlayed ?? 0
        todayProgress = goalRepo.todayProgress(sessions: todaySessions)
    }
}
