---
name: feature-goal
description: "EveryDoMath 앱에 학습 목표 설정 기능을 구현. 부모가 하루 목표 게임 수와 알림 시간을 설정하고, 홈 화면에 진행률 표시. 기능6 구현 또는 feature-goal 에이전트 실행 시 반드시 이 스킬을 사용."
---

# Feature Goal — 학습 목표 설정

## 프로젝트 컨텍스트

- **경로:** `/Users/otto/DevWork/EveryDoMath/EveryDoMath/`
- **의존:** `NotificationManager` (feature-retention이 구현), `GameRepository`
- **저장:** UserDefaults (단순, 로컬)
- **HomeView 수정:** 직접 수정하지 않고 feature-retention에게 SendMessage로 스니펫 전달

## LearningGoal.swift

```swift
import Foundation

struct LearningGoal: Codable {
    var dailySessionTarget: Int    // 하루 목표 게임 수 (1~5, 기본 2)
    var reminderHour: Int          // 알림 시간 0~23 (기본 19)
    var reminderMinute: Int        // 기본 0
    var isReminderEnabled: Bool    // 알림 활성화 여부 (기본 true)
    var gradeTarget: Grade         // 목표 학년

    static let `default` = LearningGoal(
        dailySessionTarget: 2,
        reminderHour: 19,
        reminderMinute: 0,
        isReminderEnabled: true,
        gradeTarget: .grade1
    )
}
```

## LearningGoalRepository.swift

```swift
import Foundation

final class LearningGoalRepository {
    private let defaults = UserDefaults.standard
    private let key = "learning_goal"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadGoal() -> LearningGoal {
        guard let data = defaults.data(forKey: key),
              let goal = try? decoder.decode(LearningGoal.self, from: data) else {
            return .default
        }
        return goal
    }

    func saveGoal(_ goal: LearningGoal) {
        if let data = try? encoder.encode(goal) {
            defaults.set(data, forKey: key)
        }
    }

    func todayProgress(sessions: [GameSession]) -> GoalProgress {
        let goal = loadGoal()
        let calendar = Calendar.current
        let todaySessions = sessions.filter {
            calendar.isDateInToday($0.date)
        }
        return GoalProgress(completed: todaySessions.count, target: goal.dailySessionTarget)
    }

    struct GoalProgress {
        let completed: Int
        let target: Int

        var ratio: Double {
            guard target > 0 else { return 0 }
            return min(1.0, Double(completed) / Double(target))
        }

        var isAchieved: Bool { completed >= target && target > 0 }

        var remainingCount: Int { max(0, target - completed) }
    }
}
```

## GoalProgressView.swift (홈 화면 삽입용)

```swift
import SwiftUI

struct GoalProgressView: View {
    let progress: LearningGoalRepository.GoalProgress

    var body: some View {
        HStack(spacing: 14) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(progress.isAchieved ? Color.appSuccess.opacity(0.15) : Color.appPrimaryStart.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: progress.isAchieved ? "checkmark.seal.fill" : "target")
                    .font(.system(size: 20))
                    .foregroundColor(progress.isAchieved ? .appSuccess : .appPrimaryStart)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(progress.isAchieved ? "오늘 목표 달성! 🎉" : "오늘 목표")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(progress.isAchieved ? .appSuccess : .appText)
                    Spacer()
                    Text("\(progress.completed)/\(progress.target)판")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.appSubtext)
                }

                ProgressView(value: progress.ratio)
                    .tint(progress.isAchieved ? .appSuccess : .appPrimaryStart)
                    .scaleEffect(x: 1, y: 1.4, anchor: .center)

                if !progress.isAchieved && progress.target > 0 {
                    Text("\(progress.remainingCount)판 더 하면 목표 달성!")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.appSubtext)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            progress.isAchieved ? Color.appSuccess.opacity(0.3) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
    }
}
```

## GoalSettingsView.swift (부모 대시보드 탭)

```swift
import SwiftUI

struct GoalSettingsView: View {
    @State private var goal: LearningGoal = LearningGoalRepository().loadGoal()
    @State private var isSaved = false
    private let repo = LearningGoalRepository()

    // 알림 시간을 Date로 변환 (DatePicker 연동용)
    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = goal.reminderHour
                components.minute = goal.reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                goal.reminderHour = components.hour ?? 19
                goal.reminderMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            // 하루 목표 게임 수
            VStack(alignment: .leading, spacing: 12) {
                Label("하루 목표 게임 수", systemImage: "gamecontroller.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)

                HStack {
                    Stepper(
                        "\(goal.dailySessionTarget)판",
                        value: $goal.dailySessionTarget,
                        in: 1...5
                    )
                    .font(.system(size: 17, design: .rounded))
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))

            // 알림 설정
            VStack(alignment: .leading, spacing: 12) {
                Label("학습 알림", systemImage: "bell.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)

                Toggle("알림 활성화", isOn: $goal.isReminderEnabled)
                    .font(.system(size: 15, design: .rounded))

                if goal.isReminderEnabled {
                    DatePicker(
                        "알림 시간",
                        selection: reminderDate,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 15, design: .rounded))
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))

            // 목표 학년
            VStack(alignment: .leading, spacing: 12) {
                Label("목표 학년", systemImage: "graduationcap.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)

                Picker("목표 학년", selection: $goal.gradeTarget) {
                    ForEach(Grade.allCases) { grade in
                        Text(grade.label).tag(grade)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))

            // 저장 버튼
            Button {
                saveGoal()
            } label: {
                HStack {
                    if isSaved {
                        Image(systemName: "checkmark")
                        Text("저장됨!")
                    } else {
                        Text("목표 저장")
                    }
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.appPrimaryStart, .appPrimaryEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func saveGoal() {
        repo.saveGoal(goal)
        // 알림 재스케줄
        if goal.isReminderEnabled {
            NotificationManager.shared.scheduleGoalReminder(hour: goal.reminderHour, minute: goal.reminderMinute)
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["goal-reminder"])
        }
        withAnimation {
            isSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSaved = false
        }
    }
}
```

`GoalSettingsView`에서 `import UserNotifications` 추가 필요.

## HomeViewModel 추가 사항

feature-retention에게 전달할 스니펫:

**HomeViewModel에 추가할 프로퍼티/메서드:**
```swift
var goalProgress: LearningGoalRepository.GoalProgress = LearningGoalRepository.GoalProgress(completed: 0, target: 0)
private let goalRepo = LearningGoalRepository()

// loadData() 내에 추가:
let allSessions = gameRepo.loadSessions()
goalProgress = goalRepo.todayProgress(sessions: allSessions)
```

**HomeView에 추가할 섹션 (dailyChallengeSection 직후):**
```swift
private var goalProgressSection: some View {
    Group {
        if viewModel.goalProgress.target > 0 {
            GoalProgressView(progress: viewModel.goalProgress)
                .padding(.horizontal, 20)
        }
    }
}
```
