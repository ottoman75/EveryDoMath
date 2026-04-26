import Foundation

// 학습 목표 모델
struct LearningGoal: Codable {
    var dailySessionTarget: Int     // 하루 목표 게임 횟수 (1~5)
    var gradeTarget: Grade          // 목표 학년
    var reminderHour: Int           // 알림 시각 (시)
    var reminderMinute: Int         // 알림 시각 (분)
    var isReminderEnabled: Bool     // 알림 활성화 여부

    static let `default` = LearningGoal(
        dailySessionTarget: 3,
        gradeTarget: .grade1,
        reminderHour: 19,
        reminderMinute: 0,
        isReminderEnabled: false
    )
}

// 오늘의 목표 달성 현황
struct GoalProgress {
    let goal: LearningGoal
    let todaySessions: Int

    var isAchieved: Bool { todaySessions >= goal.dailySessionTarget }

    var progressFraction: Double {
        guard goal.dailySessionTarget > 0 else { return 0 }
        return min(Double(todaySessions) / Double(goal.dailySessionTarget), 1.0)
    }

    var progressText: String {
        "\(todaySessions) / \(goal.dailySessionTarget)"
    }
}
