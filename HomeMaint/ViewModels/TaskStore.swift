import Foundation
import SwiftData
import SwiftUI

@Observable
class TaskStore {
    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        // Insert default categories if none exist
        Category.insertDefaults(into: context)
    }

    // MARK: - Category Operations

    func fetchAllCategories() -> [Category] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchActiveCategories() -> [Category] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchCategory(by id: UUID) -> Category? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    func fetchCategory(byName name: String) -> Category? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        return try? context.fetch(descriptor).first
    }

    func addCategory(_ category: Category) {
        category.name = normalizedCategoryName(category.name)
        modelContext?.insert(category)
        normalizeCategorySortOrder()
        save()
    }

    func updateCategory(_ category: Category) {
        category.name = normalizedCategoryName(category.name)
        save()
    }

    func deleteCategory(_ category: Category) {
        guard let context = modelContext else { return }
        let tasks = fetchTasksByCategory(category)
        let fallbackCategory = findFallbackCategory(excluding: category)

        for task in tasks {
            task.categoryID = fallbackCategory?.id
        }

        context.delete(category)
        normalizeCategorySortOrder()
        save()
    }

    func toggleCategoryActive(_ category: Category) {
        category.isActive.toggle()
        save()
    }

    func isCategoryNameTaken(_ name: String, excluding categoryID: UUID? = nil) -> Bool {
        let normalizedName = normalizedCategoryName(name).lowercased()
        return fetchAllCategories().contains { category in
            guard category.id != categoryID else { return false }
            return normalizedCategoryName(category.name).lowercased() == normalizedName
        }
    }

    // MARK: - Task Operations

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

    func fetchTasksByCategory(_ category: Category) -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let categoryID = category.id
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { $0.categoryID == categoryID },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchTasksByCategoryID(_ categoryID: UUID) -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { $0.categoryID == categoryID },
            sortBy: [SortDescriptor(\.nextDue)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchTasksWithNoCategory() -> [MaintenanceTask] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<MaintenanceTask>(
            predicate: #Predicate { $0.categoryID == nil },
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

        var categoryCounts: [UUID: Int] = [:]
        for category in fetchAllCategories() {
            categoryCounts[category.id] = allTasks.filter { $0.categoryID == category.id }.count
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

    func getCategoryTaskCount(_ category: Category) -> Int {
        return fetchTasksByCategory(category).count
    }

    func getCategoryOverdueCount(_ category: Category) -> Int {
        return fetchTasksByCategory(category).filter { $0.isOverdue }.count
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

    private func normalizedCategoryName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func findFallbackCategory(excluding category: Category) -> Category? {
        if let otherCategory = fetchCategory(byName: "Other"), otherCategory.id != category.id {
            return otherCategory
        }

        if let nextCategory = fetchAllCategories().first(where: { $0.id != category.id }) {
            return nextCategory
        }

        guard let context = modelContext else { return nil }
        let fallbackCategory = Category(
            name: "Other",
            icon: "tag.fill",
            color: .indigo,
            sortOrder: 0
        )
        context.insert(fallbackCategory)
        return fallbackCategory
    }

    private func normalizeCategorySortOrder() {
        let sortedCategories = fetchAllCategories()
        for (index, category) in sortedCategories.enumerated() {
            category.sortOrder = index
        }
    }

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
    let categoryCounts: [UUID: Int]

    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(normalCount + upcomingCount) / Double(totalTasks)
    }
}
