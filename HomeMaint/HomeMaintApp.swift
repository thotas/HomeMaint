import SwiftUI
import SwiftData
import UserNotifications

@main
struct HomeMaintApp: App {
    let container: ModelContainer
    @State private var notificationManager = NotificationManager.shared
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 3
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    init() {
        let schema = Schema([MaintenanceTask.self, Category.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .preferredColorScheme(.dark)
                .task {
                    await setupNotifications()
                }
        }
        .modelContainer(container)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .undoRedo) {
                Button("Undo") {
                    NotificationCenter.default.post(name: .performUndo, object: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    NotificationCenter.default.post(name: .performRedo, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            CommandMenu("Tasks") {
                Button("New Task") {
                    NotificationCenter.default.post(name: .newTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Mark Selected Complete") {
                    NotificationCenter.default.post(name: .markComplete, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
            }
        }

        Settings {
            SettingsView(notificationManager: notificationManager)
        }
    }

    private func setupNotifications() async {
        guard notificationsEnabled else { return }

        notificationManager.registerNotificationCategories()
        await notificationManager.checkAuthorizationStatus()

        // Request authorization on first launch if not determined
        if notificationManager.authorizationStatus == .notDetermined {
            let granted = await notificationManager.requestAuthorization()
            if !granted {
                return
            }
        }

        // Schedule notifications for tasks due soon
        await scheduleTaskNotifications()
    }

    private func scheduleTaskNotifications() async {
        let store = TaskStore()
        store.setContext(container.mainContext)

        let allTasks = store.fetchActiveTasks()
        await notificationManager.scheduleNotifications(for: allTasks, daysBefore: reminderDaysBefore)
    }
}

extension Notification.Name {
    static let newTask = Notification.Name("newTask")
    static let markComplete = Notification.Name("markComplete")
    static let performUndo = Notification.Name("performUndo")
    static let performRedo = Notification.Name("performRedo")
}

struct SettingsView: View {
    @AppStorage("showCompletedTasks") private var showCompletedTasks = true
    @AppStorage("defaultView") private var defaultView = "dashboard"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 3
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    @Bindable var notificationManager: NotificationManager
    @State private var showingPermissionAlert = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show Completed Tasks", isOn: $showCompletedTasks)

                Picker("Default View", selection: $defaultView) {
                    Text("Dashboard").tag("dashboard")
                    Text("All Tasks").tag("all")
                    Text("Overdue").tag("overdue")
                }
            }

            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)

                if notificationsEnabled {
                    Stepper(value: $reminderDaysBefore, in: 1...14) {
                        Text("Remind \(reminderDaysBefore) days before due")
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        statusBadge
                    }

                    if notificationManager.authorizationStatus != .authorized {
                        Button("Request Permission") {
                            Task {
                                let granted = await notificationManager.requestAuthorization()
                                if !granted {
                                    showingPermissionAlert = true
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("HomeMaint")
                        .font(.headline)
                    Spacer()
                }

                Text("Track and manage your home maintenance tasks with ease.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
        .padding()
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in System Settings to receive task reminders.")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch notificationManager.authorizationStatus {
        case .authorized:
            Text("Authorized")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
        case .denied:
            Text("Denied")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .clipShape(Capsule())
        case .notDetermined:
            Text("Not Set")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
        case .provisional:
            Text("Provisional")
                .font(.caption)
                .foregroundStyle(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Capsule())
        case .ephemeral:
            Text("Ephemeral")
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
        @unknown default:
            Text("Unknown")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}
