import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - 권한 요청

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    // MARK: - 스트릭 리마인더

    func scheduleStreakReminder(streak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])

        let content = UNMutableNotificationContent()
        if streak > 0 {
            content.title = L("notif.streak.title_active", streak)
            content.body = L("notif.streak.body_active")
        } else {
            content.title = L("notif.streak.title_new")
            content.body = L("notif.streak.body_new")
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "streak-reminder", content: content, trigger: trigger))
    }

    // MARK: - 학습 목표 알림

    func scheduleGoalReminder(hour: Int, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["goal-reminder"])

        let content = UNMutableNotificationContent()
        content.title = L("notif.goal.title")
        content.body = L("notif.goal.body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "goal-reminder", content: content, trigger: trigger))
    }

    // MARK: - 알림 취소

    func cancelStreakReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])
    }

    func cancelGoalReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["goal-reminder"])
    }
}
