import SwiftUI

struct TaskListView: View {
    let tasks: [MaintenanceTask]
    let title: String
    let taskStore: TaskStore

    @State private var selectedTask: MaintenanceTask?
    @State private var showingTaskDetail = false
    @State private var sortOption: SortOption = .dueDate

    enum SortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case name = "Name"
        case category = "Category"
        case lastCompleted = "Last Completed"
    }

    var sortedTasks: [MaintenanceTask] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { $0.nextDue < $1.nextDue }
        case .name:
            return tasks.sorted { $0.name < $1.name }
        case .category:
            return tasks.sorted { $0.category.rawValue < $1.category.rawValue }
        case .lastCompleted:
            return tasks.sorted {
                guard let lhs = $0.lastCompleted else { return false }
                guard let rhs = $1.lastCompleted else { return true }
                return lhs > rhs
            }
        }
    }

    var body: some View {
        List(sortedTasks, selection: $selectedTask) { task in
            TaskRow(task: task, taskStore: taskStore)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTask = task
                    showingTaskDetail = true
                }
                .contextMenu {
                    Button(action: { taskStore.markTaskComplete(task) }) {
                        Label("Mark Complete", systemImage: "checkmark.circle")
                    }

                    Divider()

                    Button(action: { taskStore.toggleTaskActive(task) }) {
                        Label(task.isActive ? "Deactivate" : "Activate", systemImage: task.isActive ? "pause.circle" : "play.circle")
                    }

                    Button(role: .destructive, action: { taskStore.deleteTask(task) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Sort by", systemImage: "arrow.up.arrow.down") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { sortOption = option }) {
                            Label(option.rawValue, systemImage: sortOption == option ? "checkmark" : "")
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, taskStore: taskStore)
                .frame(minWidth: 500, minHeight: 600)
        }
    }
}

struct TaskRow: View {
    let task: MaintenanceTask
    let taskStore: TaskStore

    var body: some View {
        HStack(spacing: 12) {
            // Completion Status
            Button(action: { taskStore.markTaskComplete(task) }) {
                Image(systemName: task.lastCompleted != nil && task.daysUntilDue > 0 ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(urgencyColor)
            }
            .buttonStyle(.plain)

            // Category Icon
            Image(systemName: task.category.icon)
                .font(.body)
                .foregroundStyle(categoryColor)
                .frame(width: 24)

            // Task Name
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.lastCompleted != nil && task.daysUntilDue > 0)

                HStack(spacing: 4) {
                    Text(task.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(task.frequency.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Due Status
            VStack(alignment: .trailing, spacing: 2) {
                if task.isOverdue {
                    Label("\(-task.daysUntilDue)d overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                } else if task.daysUntilDue == 0 {
                    Label("Due today", systemImage: "clock.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                } else if task.daysUntilDue <= 3 {
                    Label("\(task.daysUntilDue)d left", systemImage: "clock")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                } else {
                    Label("\(task.daysUntilDue)d", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let lastCompleted = task.lastCompleted {
                    Text("Last: \(lastCompleted, style: .date)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Never done")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var urgencyColor: Color {
        switch task.urgency {
        case .overdue: return .red
        case .dueSoon: return .orange
        case .upcoming: return .yellow
        case .normal: return .green
        }
    }

    private var categoryColor: Color {
        switch task.category {
        case .hvac: return .cyan
        case .plumbing: return .blue
        case .electrical: return .yellow
        case .exterior: return .brown
        case .interior: return .purple
        case .appliances: return .gray
        case .safety: return .red
        case .yard: return .green
        case .cleaning: return .mint
        case .other: return .indigo
        }
    }
}
