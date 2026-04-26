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
        // 알림 업데이트
        if goal.isReminderEnabled {
            NotificationManager.shared.scheduleGoalReminder(hour: goal.reminderHour, minute: goal.reminderMinute)
        } else {
            NotificationManager.shared.cancelGoalReminder()
        }
    }

    func todayProgress(sessions: Int) -> GoalProgress {
        GoalProgress(goal: load(), todaySessions: sessions)
    }
}
