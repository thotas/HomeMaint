import Foundation
import SwiftData
import SwiftUI

@Observable
class TaskStore {
    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Fetch Operations

    func fetchAllTasks() -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<MaintenanceTask>(sortBy: [SortDescriptor(\.nextDue)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchActiveTasks() -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchOverdueTasks() -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let now = Date()
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { $0.isActive && $0.nextDue < now },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchUpcomingTasks(days: Int = 7) -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { task in
                task.isActive && task.nextDue >= now && task.nextDue <= future
            },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchTasksByCategory(_ category: TaskCategory) -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { $0.categoryRaw == category.rawValue },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Statistics

    func getStatistics() -> TaskStatistics {
        let allTasks = fetchActiveTasks()
        let overdue = allTasks.filter { $0.isOverdue }.count
        let dueSoon = allTasks.filter { $0.daysUntilDue <= 3 && !$0.isOverdue }.count
        let upcoming = allTasks.filter { $0.daysUntilDue > 3 && $0.daysUntilDue <= 7 }.count
        let normal = allTasks.filter { $0.daysUntilDue > 7 }.count

        var categoryCounts: [TaskCategory: Int] = [:]
        for category in TaskCategory.allCases {
            categoryCounts[category] = allTasks.filter { $0.category == category }.count
        }

        return TaskStatistics(
            totalTasks: allTasks.count,
            overdueCount: overdue,
            dueSoonCount: dueSoon,
            upcomingCount: upcoming,
            normalCount: normal,
            categoryCounts: categoryCounts
        )
    }

    // MARK: - CRUD Operations

    func addTask(_ task: MaintenanceTask) {
        modelContext?.insert(task)
        save()
    }

    func updateTask(_ task: MaintenanceTask) {
        task.updateNextDue()
        save()
    }

    func deleteTask(_ task: MaintenanceTask) {
        modelContext?.delete(task)
        save()
    }

    func markTaskComplete(_ task: MaintenanceTask) {
        task.markAsCompleted()
        save()
    }

    func toggleTaskActive(_ task: MaintenanceTask) {
        task.isActive.toggle()
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            print("Failed to save: \(error.localizedDescription)")
        }
    }
}

struct TaskStatistics {
    let totalTasks: Int
    let overdueCount: Int
    let dueSoonCount: Int
    let upcomingCount: Int
    let normalCount: Int
    let categoryCounts: [TaskCategory: Int]

    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(normalCount + upcomingCount) / Double(totalTasks)
    }
}
