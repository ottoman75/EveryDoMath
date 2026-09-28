import Foundation

// 학습 목표 저장소 (UserDefaults)
final class LearningGoalRepository {
    private let defaults = UserDefaults.standard
    private let key = "learning_goal"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func load() -> LearningGoal {
        guard let data = defaults.data(forKey: key),
              let goal = try? decoder.decode(LearningGoal.self, from: data) else {
            return .default
        }
        return goal
    }

    func save(_ goal: LearningGoal) {
        if let data = try? encoder.encode(goal) {
            defaults.set(data, forKey: key)
        }
        // 알림 업데이트.
        // 스트릭 알림도 같이 다룬다. 이걸 빼면 부모가 알림을 끈 뒤에도 이미 등록된
        // 스트릭 알림이 다음 게임이 끝날 때까지 살아남는다.
        if goal.isReminderEnabled {
            NotificationManager.shared.scheduleGoalReminder(hour: goal.reminderHour, minute: goal.reminderMinute)
        } else {
            NotificationManager.shared.cancelGoalReminder()
            NotificationManager.shared.cancelStreakReminder()
        }
    }

    func todayProgress(sessions: Int) -> GoalProgress {
        GoalProgress(goal: load(), todaySessions: sessions)
    }
}
