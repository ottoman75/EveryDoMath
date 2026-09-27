---
name: feature-retention
description: "EveryDoMath 앱에 푸시 알림(UNUserNotificationCenter 스트릭 리마인더)과 오늘의 도전(Daily Challenge) 기능을 구현. 기능1+2 구현 또는 feature-retention 에이전트 실행 시 반드시 이 스킬을 사용."
---

# Feature Retention — 푸시 알림 + 오늘의 도전

## 프로젝트 컨텍스트

- **경로:** `/Users/otto/DevWork/EveryDoMath/EveryDoMath/`
- **Swift 버전:** 5.0 (프로젝트 설정), Swift 6.3.1 컴파일러
- **iOS 배포 타겟:** 26.4 (iOS 26)
- **아키텍처:** MVVM, `@Observable` macro (iOS 17+)
- **기존 모델:** `DailyRecord` (스트릭 추적), `GameSession`, `PlayerProfile`

## 기능 1: 푸시 알림

### NotificationManager.swift
```swift
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func scheduleStreakReminder(streak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])

        let content = UNMutableNotificationContent()
        if streak > 0 {
            content.title = "🔥 \(streak)일 연속 도전 중!"
            content.body = "오늘도 수학 문제 풀고 스트릭을 이어가요!"
        } else {
            content.title = "오늘 수학 문제 풀어볼까요? 📚"
            content.body = "매일 조금씩, 수학 실력이 쑥쑥!"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "streak-reminder", content: content, trigger: trigger))
    }

    func scheduleGoalReminder(hour: Int, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["goal-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "📖 수학 학습 시간이에요!"
        content.body = "오늘 목표를 달성해 볼까요?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "goal-reminder", content: content, trigger: trigger))
    }

    func cancelStreakReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])
    }
}
```

### EveryDoMathApp.swift 수정
`onAppear`에 알림 권한 요청 추가:
```swift
.onAppear {
    Task {
        await NotificationManager.shared.requestPermission()
        let streak = ProfileRepository().loadStreak()
        NotificationManager.shared.scheduleStreakReminder(streak: streak)
    }
}
```
단, `ProfileRepository`에 `loadStreak()` 메서드가 없으면 `GameRepository`에서 스트릭을 계산하거나 간단히 `0`으로 초기화 후 추후 업데이트.

## 기능 2: 오늘의 도전

### DailyChallenge.swift
```swift
import Foundation

struct DailyChallenge: Codable, Identifiable {
    let id: String           // "yyyy-MM-dd" 형식
    let type: ChallengeType
    var isCompleted: Bool
    var completedAt: Date?

    enum ChallengeType: String, Codable, CaseIterable {
        case speedRun      // 1분 안에 15개 이상 정답
        case perfect       // 20문제 전부 맞히기
        case comboMaster   // 10개 연속 정답
        case gradeHunter   // S등급 달성
        case consistency   // 오늘 3판 플레이

        var title: String {
            switch self {
            case .speedRun:    return "스피드 런"
            case .perfect:     return "완벽한 도전"
            case .comboMaster: return "콤보 마스터"
            case .gradeHunter: return "S등급 도전"
            case .consistency: return "꾸준한 학습"
            }
        }

        var description: String {
            switch self {
            case .speedRun:    return "1분 안에 15개 이상 맞히기"
            case .perfect:     return "20문제를 모두 맞히기"
            case .comboMaster: return "10개 연속으로 맞히기"
            case .gradeHunter: return "S등급 달성하기"
            case .consistency: return "오늘 3판 플레이하기"
            }
        }

        var iconName: String {
            switch self {
            case .speedRun:    return "bolt.fill"
            case .perfect:     return "crown.fill"
            case .comboMaster: return "flame.fill"
            case .gradeHunter: return "star.fill"
            case .consistency: return "calendar.badge.checkmark"
            }
        }

        var iconColor: String {
            switch self {
            case .speedRun:    return "appWarning"   // 노랑
            case .perfect:     return "appSuccess"   // 초록
            case .comboMaster: return "appDanger"    // 빨강
            case .gradeHunter: return "appPrimaryStart" // 파랑
            case .consistency: return "appSubtext"   // 회색
            }
        }
    }

    // 날짜 기반 결정적 챌린지 생성
    static func today() -> DailyChallenge {
        let dateString = DailyRecord.todayString
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let month = calendar.component(.month, from: Date())
        let index = (day + month) % ChallengeType.allCases.count
        let type = ChallengeType.allCases[index]
        return DailyChallenge(id: dateString, type: type, isCompleted: false, completedAt: nil)
    }

    // 게임 세션으로 챌린지 달성 여부 판정
    func isAchieved(by session: GameSession, totalTodaySessions: Int) -> Bool {
        switch type {
        case .speedRun:
            return session.timeTaken <= 60.0 && session.correctCount >= 15
        case .perfect:
            return session.correctCount == GameSession.problemCount
        case .comboMaster:
            // 세션에서 최대 연속 정답 계산 필요
            return checkCombo(session: session, required: 10)
        case .gradeHunter:
            return session.gameGrade == .S
        case .consistency:
            return totalTodaySessions >= 3
        }
    }

    private func checkCombo(session: GameSession, required: Int) -> Bool {
        var maxCombo = 0
        var currentCombo = 0
        for (problem, answer) in zip(session.problems, session.userAnswers) {
            if let answer, problem.isCorrectAnswer(answer) {
                currentCombo += 1
                maxCombo = max(maxCombo, currentCombo)
            } else {
                currentCombo = 0
            }
        }
        return maxCombo >= required
    }
}
```

### DailyChallengeRepository.swift
```swift
import Foundation

final class DailyChallengeRepository {
    private let defaults = UserDefaults.standard
    private let key = "daily_challenge"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadChallenge() -> DailyChallenge {
        let today = DailyRecord.todayString
        if let data = defaults.data(forKey: key),
           let saved = try? decoder.decode(DailyChallenge.self, from: data),
           saved.id == today {
            return saved
        }
        // 오늘 챌린지가 없으면 새로 생성
        let fresh = DailyChallenge.today()
        save(fresh)
        return fresh
    }

    func save(_ challenge: DailyChallenge) {
        if let data = try? encoder.encode(challenge) {
            defaults.set(data, forKey: key)
        }
    }

    func markCompleted() {
        var challenge = loadChallenge()
        challenge.isCompleted = true
        challenge.completedAt = Date()
        save(challenge)
    }
}
```

### DailyChallengeCardView.swift
```swift
import SwiftUI

struct DailyChallengeCardView: View {
    let challenge: DailyChallenge
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { if !challenge.isCompleted { onTap?() } }) {
            HStack(spacing: 16) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(challenge.isCompleted ? 0.3 : 0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : challenge.type.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(challenge.isCompleted ? .appSuccess : iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("오늘의 도전")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.appSubtext)
                        Spacer()
                        if challenge.isCompleted {
                            Text("완료!")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.appSuccess)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.appSuccess.opacity(0.15)))
                        }
                    }
                    Text(challenge.type.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                    Text(challenge.type.description)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.appSubtext)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(challenge.isCompleted ? Color.appSuccess.opacity(0.4) : iconColor.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(challenge.isCompleted ? 0.85 : 1.0)
    }

    private var iconColor: Color {
        switch challenge.type {
        case .speedRun:    return .appWarning
        case .perfect:     return .appSuccess
        case .comboMaster: return .appDanger
        case .gradeHunter: return .appPrimaryStart
        case .consistency: return .appSubtext
        }
    }
}
```

## HomeView 통합

### HomeViewModel에 추가
```swift
var dailyChallenge: DailyChallenge = DailyChallenge.today()
var goalProgress: LearningGoalRepository.GoalProgress = .init(completed: 0, target: 0)
private let challengeRepo = DailyChallengeRepository()
private let goalRepo = LearningGoalRepository()

// loadData() 내에 추가:
dailyChallenge = challengeRepo.loadChallenge()
let goal = goalRepo.loadGoal()
let todaySessions = loadTodaySessions()
goalProgress = goalRepo.todayProgress(sessions: todaySessions)

// 게임 완료 후 챌린지 달성 확인
func checkChallengeCompletion(session: GameSession) {
    let todayCount = loadTodaySessions().count
    if dailyChallenge.isAchieved(by: session, totalTodaySessions: todayCount) && !dailyChallenge.isCompleted {
        challengeRepo.markCompleted()
        dailyChallenge = challengeRepo.loadChallenge()
    }
}
```

### HomeView 섹션 추가 (dailyChallengeSection)
```swift
private var dailyChallengeSection: some View {
    DailyChallengeCardView(challenge: viewModel.dailyChallenge) {
        let session = GameSession.createNew(grade: viewModel.selectedGrade)
        appState.navigationPath.append(AppDestination.game(session))
    }
    .padding(.horizontal, 20)
}
```

## 에러 처리

- 알림 권한 거부: 알림 스케줄링 silently skip
- 챌린지 저장 실패: 기본값 사용 (크래시 방지 최우선)
