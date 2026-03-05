import SwiftUI
import SwiftData

@main
struct HomeMaintApp: App {
    let container: ModelContainer

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
        }
        .modelContainer(container)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
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
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let newTask = Notification.Name("newTask")
    static let markComplete = Notification.Name("markComplete")
}

struct SettingsView: View {
    @AppStorage("showCompletedTasks") private var showCompletedTasks = true
    @AppStorage("defaultView") private var defaultView = "dashboard"
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 3

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
                Stepper(value: $reminderDaysBefore, in: 1...14) {
                    Text("Remind \(reminderDaysBefore) days before due")
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
        .frame(width: 400, height: 350)
        .padding()
    }
}
