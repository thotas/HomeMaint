import Foundation
import UserNotifications

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    private(set) var isAuthorized = false
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Scheduling Notifications

    func scheduleNotifications(for tasks: [MaintenanceTask], daysBefore: Int = 3) async {
        // First, remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard isAuthorized else { return }

        let center = UNUserNotificationCenter.current()

        for task in tasks where task.isActive {
            // Schedule notification for overdue tasks
            if task.isOverdue {
                let content = UNMutableNotificationContent()
                content.title = "Overdue Task"
                content.body = "\(task.name) is overdue!"
                content.sound = .default
                content.categoryIdentifier = "TASK_REMINDER"

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "task-\(task.id.uuidString)-overdue",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Failed to schedule overdue notification: \(error)")
                }
            }
            // Schedule notification for tasks due within daysBefore
            else if task.daysUntilDue <= daysBefore && task.daysUntilDue >= 0 {
                let content = UNMutableNotificationContent()
                if task.daysUntilDue == 0 {
                    content.title = "Task Due Today"
                    content.body = "\(task.name) is due today!"
                } else if task.daysUntilDue == 1 {
                    content.title = "Task Due Tomorrow"
                    content.body = "\(task.name) is due tomorrow!"
                } else {
                    content.title = "Task Due Soon"
                    content.body = "\(task.name) is due in \(task.daysUntilDue) days"
                }
                content.sound = .default
                content.categoryIdentifier = "TASK_REMINDER"

                // Schedule for next morning at 9 AM
                var dateComponents = DateComponents()
                dateComponents.hour = 9
                dateComponents.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "task-\(task.id.uuidString)-\(task.daysUntilDue)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("Failed to schedule due soon notification: \(error)")
                }
            }
        }
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let markCompleteAction = UNNotificationAction(
            identifier: "MARK_COMPLETE",
            title: "Mark Complete",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [markCompleteAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([taskCategory])
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
