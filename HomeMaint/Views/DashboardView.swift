import SwiftUI
import SwiftData

struct DashboardView: View {
    let taskStore: TaskStore
    @State private var statistics: TaskStatistics?
    @State private var selectedTask: MaintenanceTask?

    var body: some View {
        ZStack {
            // Dark background gradient
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.indigo)

                            Text("HomeMaint")
                                .font(.largeTitle.bold())
                        }

                        Text("Track and manage your home maintenance tasks")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                    // Statistics Cards
                    if let stats = statistics {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Total",
                                value: stats.totalTasks,
                                icon: "list.bullet",
                                color: .indigo
                            )

                            StatCard(
                                title: "Overdue",
                                value: stats.overdueCount,
                                icon: "exclamationmark.triangle.fill",
                                color: .red
                            )

                            StatCard(
                                title: "Due Soon",
                                value: stats.dueSoonCount,
                                icon: "clock.fill",
                                color: .orange
                            )

                            StatCard(
                                title: "Healthy",
                                value: stats.normalCount + stats.upcomingCount,
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }

                        // Completion Rate
                        CompletionRateView(rate: stats.completionRate)
                    }

                    // Priority Tasks Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(.orange)
                            Text("Priority Tasks")
                                .font(.title2.bold())
                            Spacer()
                        }

                        PriorityTasksList(taskStore: taskStore, selectedTask: $selectedTask)
                    }

                    // Categories Overview
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.indigo)
                            Text("Categories")
                                .font(.title2.bold())
                            Spacer()
                        }

                        CategoriesOverview(taskStore: taskStore)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dashboard")
        .onAppear {
            statistics = taskStore.getStatistics()
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, taskStore: taskStore)
                .frame(minWidth: 500, minHeight: 600)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()
            }

            Text("\(value)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)

            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.4), lineWidth: 1.5)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct CompletionRateView: View {
    let rate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.indigo)
                Text("Completion Rate")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(Int(rate * 100))%")
                    .font(.title3.bold())
                    .foregroundStyle(rateColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(rateGradient)
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * rate)), height: 16)
                        .shadow(color: rateColor.opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 16)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var rateColor: Color {
        if rate >= 0.8 { return .green }
        if rate >= 0.6 { return .yellow }
        if rate >= 0.4 { return .orange }
        return .red
    }

    private var rateGradient: LinearGradient {
        LinearGradient(
            colors: [rateColor.opacity(0.8), rateColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct PriorityTasksList: View {
    let taskStore: TaskStore
    @Binding var selectedTask: MaintenanceTask?

    var priorityTasks: [MaintenanceTask] {
        let overdue = taskStore.fetchOverdueTasks()
        let upcoming = taskStore.fetchUpcomingTasks(days: 3)
        return (overdue + upcoming).sorted { $0.nextDue < $1.nextDue }
    }

    var body: some View {
        if priorityTasks.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle.fill",
                title: "All caught up!",
                message: "No urgent tasks right now."
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(priorityTasks.prefix(5), id: \.id) { task in
                    Button {
                        selectedTask = task
                    } label: {
                        PriorityTaskRow(task: task, taskStore: taskStore)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PriorityTaskRow: View {
    let task: MaintenanceTask
    let taskStore: TaskStore

    var category: Category? {
        task.getCategory(from: taskStore)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill((category?.color.swiftColor ?? .gray).opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: category?.icon ?? "tag.fill")
                    .font(.title3)
                    .foregroundStyle(category?.color.swiftColor ?? .gray)
            }

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(category?.name ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text("•")
                        .foregroundStyle(.gray)

                    Text(task.frequency.rawValue)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            // Due Date
            VStack(alignment: .trailing, spacing: 4) {
                if task.isOverdue {
                    Label("\(-task.daysUntilDue) days overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                } else {
                    Label(task.daysUntilDue == 0 ? "Due today" : "Due in \(task.daysUntilDue) days", systemImage: "clock")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }

                Text(task.nextDue, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(task.isOverdue ? Color.red.opacity(0.5) : Color.orange.opacity(0.5), lineWidth: 1.5)
                )
        )
        .shadow(color: task.isOverdue ? Color.red.opacity(0.1) : Color.orange.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CategoriesOverview: View {
    let taskStore: TaskStore

    var body: some View {
        let categories = taskStore.fetchActiveCategories()
        if categories.isEmpty {
            EmptyStateView(
                icon: "folder.badge.questionmark",
                title: "No categories",
                message: "Add categories to organize your tasks."
            )
        } else {
            LazyVStack(spacing: 8) {
                ForEach(categories.prefix(5)) { category in
                    CategoryOverviewRow(category: category, taskStore: taskStore)
                }
            }
        }
    }
}

struct CategoryOverviewRow: View {
    let category: Category
    let taskStore: TaskStore

    var taskCount: Int {
        taskStore.getCategoryTaskCount(category)
    }

    var overdueCount: Int {
        taskStore.getCategoryOverdueCount(category)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(category.color.swiftColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.swiftColor.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body.bold())
                    .foregroundStyle(.white)

                Text("\(taskCount) tasks")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if overdueCount > 0 {
                Text("\(overdueCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
