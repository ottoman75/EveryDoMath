---
name: feature-parent
description: "EveryDoMath 앱에 부모 대시보드(주간 학습 통계, 연산별 정답률, 달력 히트맵)와 가족 리더보드(Firebase Firestore 그룹 코드) 기능을 구현. 기능4+5 구현 또는 feature-parent 에이전트 실행 시 반드시 이 스킬을 사용."
---

# Feature Parent — 부모 대시보드 + 가족 리더보드

## 프로젝트 컨텍스트

- **경로:** `/Users/otto/DevWork/EveryDoMath/EveryDoMath/`
- **Firebase Firestore:** 이미 패키지에 추가됨, `import FirebaseFirestore` 사용 가능
- **기존 저장소:** `GameRepository`, `ProfileRepository`, `RemoteLeaderboardRepository`
- **기존 모델:** `GameSession`, `DailyRecord`, `LeaderboardEntry`, `MathOperation`
- **AppState 위치:** `App/AppState.swift`

## FamilyGroup.swift

```swift
import Foundation

struct FamilyGroup: Codable, Identifiable {
    let id: String           // Firestore document ID
    let code: String         // 6자리 초대 코드 (예: "ABC123")
    var name: String         // 가족 이름
    var memberIds: [String]
    let createdAt: Date

    static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
```

## FamilyGroupRepository.swift

```swift
import Foundation
import FirebaseFirestore

final class FamilyGroupRepository {
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard
    private let groupIdKey = "family_group_id"

    var currentGroupId: String? {
        get { defaults.string(forKey: groupIdKey) }
        set { defaults.set(newValue, forKey: groupIdKey) }
    }

    func createGroup(name: String, userId: String) async throws -> FamilyGroup {
        let code = FamilyGroup.generateCode()
        let group = FamilyGroup(
            id: code,
            code: code,
            name: name,
            memberIds: [userId],
            createdAt: Date()
        )
        let data: [String: Any] = [
            "code": group.code,
            "name": group.name,
            "memberIds": group.memberIds,
            "createdAt": Timestamp(date: group.createdAt)
        ]
        try await db.collection("familyGroups").document(code).setData(data)
        currentGroupId = code
        return group
    }

    func joinGroup(code: String, userId: String) async throws -> FamilyGroup {
        let docRef = db.collection("familyGroups").document(code.uppercased())
        let snapshot = try await docRef.getDocument()
        guard snapshot.exists, var data = snapshot.data() else {
            throw FamilyGroupError.notFound
        }
        var memberIds = data["memberIds"] as? [String] ?? []
        if !memberIds.contains(userId) {
            memberIds.append(userId)
            try await docRef.updateData(["memberIds": memberIds])
        }
        currentGroupId = code.uppercased()
        return FamilyGroup(
            id: code.uppercased(),
            code: code.uppercased(),
            name: data["name"] as? String ?? "",
            memberIds: memberIds,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func fetchFamilyLeaderboard(groupId: String) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection("familyGroups").document(groupId).getDocument()
        guard let memberIds = snapshot.data()?["memberIds"] as? [String] else { return [] }

        let leaderboardSnapshot = try await db.collection("leaderboard")
            .whereField("userId", in: memberIds.isEmpty ? ["_none"] : memberIds)
            .order(by: "score", descending: true)
            .limit(to: 20)
            .getDocuments()

        return leaderboardSnapshot.documents.enumerated().compactMap { index, doc in
            LeaderboardEntry(rank: index + 1, data: doc.data())
        }
    }

    func leaveGroup() async throws {
        guard let groupId = currentGroupId else { return }
        let userId = UserIdentityRepository.shared.userId
        let docRef = db.collection("familyGroups").document(groupId)
        let snapshot = try await docRef.getDocument()
        if var memberIds = snapshot.data()?["memberIds"] as? [String] {
            memberIds.removeAll { $0 == userId }
            try await docRef.updateData(["memberIds": memberIds])
        }
        currentGroupId = nil
    }

    enum FamilyGroupError: LocalizedError {
        case notFound
        var errorDescription: String? {
            switch self {
            case .notFound: return "해당 그룹 코드를 찾을 수 없습니다."
            }
        }
    }
}
```

## WeeklyStats 구조체 (ParentDashboardViewModel 내부)

```swift
struct WeeklyStats {
    var totalSessions: Int = 0
    var totalCorrect: Int = 0
    var totalProblems: Int = 0
    var bestScore: Int = 0
    var activeDays: Int = 0

    var averageAccuracy: Double {
        guard totalProblems > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalProblems)
    }

    static let empty = WeeklyStats()
}
```

## ParentDashboardViewModel.swift

```swift
import Foundation

@Observable
final class ParentDashboardViewModel {
    var weeklyStats: WeeklyStats = .empty
    var operationAccuracy: [(operation: MathOperation, accuracy: Double)] = []
    var dailyRecords: [DailyRecord] = []
    var familyGroup: FamilyGroup?
    var familyLeaderboard: [LeaderboardEntry] = []
    var isLoading = false
    var errorMessage: String?
    var showGroupSheet = false
    var groupCodeInput = ""

    private let gameRepo = GameRepository()
    private let profileRepo = ProfileRepository()
    private let familyRepo = FamilyGroupRepository()

    func loadDashboard() {
        let sessions = gameRepo.loadSessions()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessions = sessions.filter { $0.date >= weekAgo }

        // 주간 통계 계산
        var stats = WeeklyStats()
        var activeDateStrings = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for session in recentSessions {
            stats.totalSessions += 1
            stats.totalCorrect += session.correctCount
            stats.totalProblems += GameSession.problemCount
            stats.bestScore = max(stats.bestScore, session.score)
            activeDateStrings.insert(formatter.string(from: session.date))
        }
        stats.activeDays = activeDateStrings.count
        weeklyStats = stats

        // 연산별 정답률
        computeOperationAccuracy(sessions: sessions.prefix(50).map { $0 })

        // 일일 기록 (30일)
        loadDailyRecords(sessions: sessions)

        // 가족 그룹
        Task { await loadFamilyData() }
    }

    private func computeOperationAccuracy(sessions: [GameSession]) {
        var correctByOp: [MathOperation: Int] = [:]
        var totalByOp: [MathOperation: Int] = [:]

        for session in sessions {
            for (problem, answer) in zip(session.problems, session.userAnswers) {
                let op = problem.operation
                totalByOp[op, default: 0] += 1
                if let ans = answer, problem.isCorrectAnswer(ans) {
                    correctByOp[op, default: 0] += 1
                }
            }
        }

        operationAccuracy = MathOperation.allCases.compactMap { op in
            guard let total = totalByOp[op], total > 0 else { return nil }
            let correct = correctByOp[op] ?? 0
            return (operation: op, accuracy: Double(correct) / Double(total))
        }
    }

    private func loadDailyRecords(sessions: [GameSession]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        var records: [String: DailyRecord] = [:]

        for session in sessions {
            let dateStr = formatter.string(from: session.date)
            if var record = records[dateStr] {
                record.sessionsPlayed += 1
                record.bestScore = max(record.bestScore, session.score)
                records[dateStr] = record
            } else {
                records[dateStr] = DailyRecord(dateString: dateStr, sessionsPlayed: 1, bestScore: session.score, streak: 1)
            }
        }

        // 최근 30일 날짜 목록
        dailyRecords = (0..<30).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let dateStr = formatter.string(from: date)
            return records[dateStr] ?? DailyRecord(dateString: dateStr, sessionsPlayed: 0, bestScore: 0, streak: 0)
        }.reversed()
    }

    @MainActor
    func loadFamilyData() async {
        guard let groupId = familyRepo.currentGroupId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            familyLeaderboard = try await familyRepo.fetchFamilyLeaderboard(groupId: groupId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createGroup(name: String) {
        let userId = UserIdentityRepository.shared.userId
        Task {
            do {
                familyGroup = try await familyRepo.createGroup(name: name, userId: userId)
                await loadFamilyData()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }

    func joinGroup() {
        let userId = UserIdentityRepository.shared.userId
        Task {
            do {
                familyGroup = try await familyRepo.joinGroup(code: groupCodeInput, userId: userId)
                groupCodeInput = ""
                await loadFamilyData()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
}
```

## ParentDashboardView.swift

```swift
import SwiftUI

struct ParentDashboardView: View {
    @State private var viewModel = ParentDashboardViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 탭 선택
                    Picker("", selection: $selectedTab) {
                        Text("학습 현황").tag(0)
                        Text("가족 리더보드").tag(1)
                        Text("목표 설정").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if selectedTab == 0 {
                        learningStatsTab
                    } else if selectedTab == 1 {
                        familyLeaderboardTab
                    } else {
                        GoalSettingsView()
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("부모 대시보드")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadDashboard() }
    }

    // MARK: - 학습 현황 탭

    private var learningStatsTab: some View {
        VStack(spacing: 16) {
            weeklyStatsCard
            operationAccuracyCard
            calendarHeatmapCard
        }
        .padding(.horizontal, 20)
    }

    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이번 주 학습 현황")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCell(title: "플레이", value: "\(viewModel.weeklyStats.totalSessions)회", icon: "gamecontroller.fill", color: .appPrimaryStart)
                statCell(title: "학습일", value: "\(viewModel.weeklyStats.activeDays)일", icon: "calendar", color: .appSuccess)
                statCell(title: "정답률", value: String(format: "%.0f%%", viewModel.weeklyStats.averageAccuracy * 100), icon: "checkmark.circle.fill", color: .appWarning)
                statCell(title: "최고점수", value: "\(viewModel.weeklyStats.bestScore)", icon: "crown.fill", color: .appDanger)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCard))
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.appSubtext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.appBackground))
    }

    private var operationAccuracyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("연산별 정답률")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            if viewModel.operationAccuracy.isEmpty {
                Text("아직 데이터가 없습니다")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.appSubtext)
            } else {
                ForEach(viewModel.operationAccuracy, id: \.operation) { item in
                    HStack(spacing: 12) {
                        Text(item.operation.symbol)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.appText)
                            .frame(width: 24)
                        ProgressView(value: item.accuracy)
                            .tint(accuracyColor(item.accuracy))
                        Text(String(format: "%.0f%%", item.accuracy * 100))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.appSubtext)
                            .frame(width: 40)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCard))
    }

    private var calendarHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30일 학습 기록")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(viewModel.dailyRecords) { record in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(heatmapColor(sessions: record.sessionsPlayed))
                        .frame(height: 32)
                        .overlay(
                            Text(dayLabel(from: record.dateString))
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(record.sessionsPlayed > 0 ? .white.opacity(0.8) : .appSubtext)
                        )
                }
            }

            // 범례
            HStack(spacing: 8) {
                Text("적음")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.appSubtext)
                ForEach([0, 1, 2, 3], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatmapColor(sessions: level))
                        .frame(width: 16, height: 16)
                }
                Text("많음")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.appSubtext)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCard))
    }

    // MARK: - 가족 리더보드 탭

    private var familyLeaderboardTab: some View {
        VStack(spacing: 16) {
            FamilyLeaderboardView(viewModel: viewModel)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .appSuccess }
        if accuracy >= 0.6 { return .appWarning }
        return .appDanger
    }

    private func heatmapColor(sessions: Int) -> Color {
        switch sessions {
        case 0: return Color.appCard
        case 1: return Color.appPrimaryStart.opacity(0.4)
        case 2: return Color.appPrimaryStart.opacity(0.7)
        default: return Color.appPrimaryStart
        }
    }

    private func dayLabel(from dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        guard parts.count == 3, let day = Int(parts[2]) else { return "" }
        return "\(day)"
    }
}
```

## FamilyLeaderboardView.swift

```swift
import SwiftUI

struct FamilyLeaderboardView: View {
    @Bindable var viewModel: ParentDashboardViewModel
    @State private var showCreateSheet = false
    @State private var newGroupName = ""
    private let familyRepo = FamilyGroupRepository()

    var body: some View {
        VStack(spacing: 16) {
            if familyRepo.currentGroupId == nil {
                // 그룹 없음 상태
                noGroupView
            } else {
                // 그룹 있음: 리더보드 표시
                groupInfoCard
                leaderboardList
            }
        }
    }

    private var noGroupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.appSubtext)
            Text("가족 그룹을 만들어 함께 경쟁해요!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
                .multilineTextAlignment(.center)

            // 그룹 생성
            VStack(spacing: 8) {
                TextField("가족 이름 입력", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                Button("그룹 만들기") {
                    guard !newGroupName.isEmpty else { return }
                    viewModel.createGroup(name: newGroupName)
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("또는")
                .foregroundColor(.appSubtext)

            // 코드로 참가
            VStack(spacing: 8) {
                TextField("초대 코드 입력 (예: ABC123)", text: $viewModel.groupCodeInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                Button("참가하기") {
                    viewModel.joinGroup()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimaryStart)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCard))
    }

    private var groupInfoCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.familyGroup?.name ?? "우리 가족")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                if let code = familyRepo.currentGroupId {
                    Text("초대 코드: \(code)")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.appSubtext)
                }
            }
            Spacer()
            Button {
                UIPasteboard.general.string = familyRepo.currentGroupId
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.appPrimaryStart)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.appCard))
    }

    private var leaderboardList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.familyLeaderboard) { entry in
                HStack(spacing: 12) {
                    Text("\(entry.rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(rankColor(entry.rank))
                        .frame(width: 28)
                    Text(entry.nickname)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.appText)
                    Spacer()
                    Text("\(entry.score)점")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.isCurrentUser ? Color.appPrimaryStart.opacity(0.1) : Color.appCard)
                )
            }
            if viewModel.familyLeaderboard.isEmpty {
                Text("아직 기록이 없습니다")
                    .foregroundColor(.appSubtext)
                    .padding()
            }
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .appWarning
        case 2: return .appSubtext
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .appText
        }
    }
}
```

## AppState.swift 수정

`AppDestination` enum에 추가:
```swift
case parentDashboard
```

NavigationPath를 처리하는 뷰에서 `.navigationDestination(for: AppDestination.self)` 내에 추가:
```swift
case .parentDashboard:
    ParentDashboardView()
```

## MathOperation 확장 필요 시

`MathOperation`에 `symbol` 프로퍼티가 없으면 추가:
```swift
var symbol: String {
    switch self {
    case .addition: return "+"
    case .subtraction: return "−"
    case .multiplication: return "×"
    case .division: return "÷"
    }
}
```

`MathOperation.allCases`가 필요하면 `CaseIterable` 채택 확인.
