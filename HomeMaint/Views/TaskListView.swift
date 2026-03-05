import SwiftUI
import SwiftData

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
            return tasks.sorted { (task1, task2) in
                let name1 = task1.getCategory(from: taskStore)?.name ?? ""
                let name2 = task2.getCategory(from: taskStore)?.name ?? ""
                return name1 < name2
            }
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
            TaskRow(task: task, taskStore: taskStore, onSelect: {
                selectedTask = task
                showingTaskDetail = true
            })
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
    let onSelect: () -> Void

    var category: Category? {
        task.getCategory(from: taskStore)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Completion Status Button
            Button {
                taskStore.markTaskComplete(task)
            } label: {
                Image(systemName: task.lastCompleted != nil && task.daysUntilDue > 0 ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(urgencyColor)
            }
            .buttonStyle(.borderless)

            // Main content area (clickable for detail)
            HStack(spacing: 12) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill((category?.color.swiftColor ?? .gray).opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: category?.icon ?? "tag.fill")
                        .font(.caption)
                        .foregroundStyle(category?.color.swiftColor ?? .gray)
                }

                // Task Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .font(.body)
                        .foregroundStyle(.white)
                        .strikethrough(task.lastCompleted != nil && task.daysUntilDue > 0)

                    HStack(spacing: 4) {
                        Text(category?.name ?? "Unknown")
                            .font(.caption2)
                            .foregroundStyle(.gray)

                        Text("•")
                            .foregroundStyle(.gray)

                        Text(task.frequency.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.gray)
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
                            .foregroundStyle(.gray)
                    }

                    if let lastCompleted = task.lastCompleted {
                        Text("Last: \(lastCompleted, style: .date)")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    } else {
                        Text("Never done")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
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
}
