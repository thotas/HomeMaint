import Foundation
import SwiftData
import SwiftUI

@Observable
class TaskStore {
    private var modelContext: ModelContext?
    private var undoStack: [UndoableAction] = []
    private var redoStack: [UndoableAction] = []
    private let maxUndoLevels = 20

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var undoActionName: String? { undoStack.last?.actionName }
    var redoActionName: String? { redoStack.last?.actionName }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        // Insert default categories if none exist
        Category.insertDefaults(into: context)
        migrateTasksToCategoryIDsIfNeeded()
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

    func deleteTask(_ task: MaintenanceTask, saveForUndo: Bool = true) {
        if saveForUndo {
            // Store a copy of the task data for undo
            let taskCopy = MaintenanceTask(
                id: task.id,
                name: task.name,
                taskDescription: task.taskDescription,
                categoryID: task.categoryID,
                frequency: task.frequency,
                lastCompleted: task.lastCompleted,
                isActive: task.isActive,
                notes: task.notes,
                estimatedDuration: task.estimatedDuration
            )
            taskCopy.nextDue = task.nextDue

            addToUndoStack(.deleteTask(taskCopy))
        }

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

    static func resolveCategoryID(
        taskName: String,
        legacyCategoryRaw: String?,
        categoriesByName: [String: UUID],
        sampleTaskCategoryByName: [String: String],
        fallbackCategoryID: UUID?
    ) -> UUID? {
        let normalizedTaskName = normalizedKey(taskName)
        let normalizedLegacy = normalizedKey(legacyCategoryRaw)

        if let legacyName = normalizedLegacy {
            if let categoryID = categoriesByName[legacyName] {
                return categoryID
            }
            return fallbackCategoryID
        }

        if
            let normalizedTaskName,
            let sampleCategoryName = sampleTaskCategoryByName[normalizedTaskName]
        {
            return categoriesByName[sampleCategoryName]
        }

        return nil
    }

    private func migrateTasksToCategoryIDsIfNeeded() {
        guard !fetchTasksWithNoCategory().isEmpty else { return }

        let categoriesByName = fetchAllCategories().reduce(into: [String: UUID]()) { result, category in
            guard let key = Self.normalizedKey(category.name), result[key] == nil else { return }
            result[key] = category.id
        }
        let sampleTaskCategoryByName = SampleData.tasks.reduce(into: [String: String]()) { result, task in
            guard
                let taskNameKey = Self.normalizedKey(task.name),
                let categoryNameKey = Self.normalizedKey(task.category.rawValue),
                result[taskNameKey] == nil
            else { return }
            result[taskNameKey] = categoryNameKey
        }
        let fallbackCategoryID = categoriesByName[Self.normalizedKey("Other") ?? "other"]

        var didChange = false

        for task in fetchTasksWithNoCategory() {
            let resolvedCategoryID = Self.resolveCategoryID(
                taskName: task.name,
                legacyCategoryRaw: task.legacyCategoryRaw,
                categoriesByName: categoriesByName,
                sampleTaskCategoryByName: sampleTaskCategoryByName,
                fallbackCategoryID: fallbackCategoryID
            )

            if let resolvedCategoryID {
                task.categoryID = resolvedCategoryID
                didChange = true
            }

            if task.legacyCategoryRaw != nil {
                task.legacyCategoryRaw = nil
                didChange = true
            }
        }

        if didChange {
            save()
        }
    }

    private static func normalizedKey(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.lowercased()
    }

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
            ErrorManager.shared.handleError(error)
        }
    }

    // MARK: - Undo/Redo Support

    private func addToUndoStack(_ action: UndoableAction) {
        undoStack.append(action)
        redoStack.removeAll()

        // Limit undo stack size
        if undoStack.count > maxUndoLevels {
            undoStack.removeFirst()
        }
    }

    func performUndo() {
        guard let action = undoStack.popLast() else { return }

        switch action {
        case .deleteTask(let task):
            // Re-insert the deleted task
            modelContext?.insert(task)
            save()
            redoStack.append(action)

        case .deleteCategory(let category, let tasks):
            // Re-insert the deleted category and restore task associations
            modelContext?.insert(category)
            for task in tasks {
                task.categoryID = category.id
            }
            save()
            redoStack.append(UndoableAction.deleteCategory(category, tasks))

        case .updateTask(let task, let snapshot):
            // Restore task to previous state
            if let currentTask = fetchAllTasks().first(where: { $0.id == task.id }) {
                let currentSnapshot = TaskSnapshot(from: currentTask)
                snapshot.restore(to: currentTask)
                save()
                redoStack.append(UndoableAction.updateTask(currentTask, currentSnapshot))
            }

        case .updateCategory(let category, let snapshot):
            // Restore category to previous state
            if let currentCategory = fetchAllCategories().first(where: { $0.id == category.id }) {
                let currentSnapshot = CategorySnapshot(from: currentCategory)
                snapshot.restore(to: currentCategory)
                save()
                redoStack.append(UndoableAction.updateCategory(currentCategory, currentSnapshot))
            }
        }
    }

    func performRedo() {
        guard let action = redoStack.popLast() else { return }

        switch action {
        case .deleteTask(let task):
            // Delete the task again
            if let taskToDelete = fetchAllTasks().first(where: { $0.id == task.id }) {
                modelContext?.delete(taskToDelete)
                save()
                undoStack.append(UndoableAction.deleteTask(task))
            }

        case .deleteCategory(let category, let tasks):
            // Delete the category again
            if let categoryToDelete = fetchAllCategories().first(where: { $0.id == category.id }) {
                let tasksToUpdate = fetchTasksByCategory(categoryToDelete)
                let fallbackCategory = findFallbackCategory(excluding: categoryToDelete)

                for task in tasksToUpdate {
                    task.categoryID = fallbackCategory?.id
                }

                modelContext?.delete(categoryToDelete)
                save()
                undoStack.append(UndoableAction.deleteCategory(category, tasks))
            }

        case .updateTask(let task, let snapshot):
            // Apply the update again
            if let currentTask = fetchAllTasks().first(where: { $0.id == task.id }) {
                let currentSnapshot = TaskSnapshot(from: currentTask)
                snapshot.restore(to: currentTask)
                save()
                undoStack.append(UndoableAction.updateTask(currentTask, currentSnapshot))
            }

        case .updateCategory(let category, let snapshot):
            // Apply the update again
            if let currentCategory = fetchAllCategories().first(where: { $0.id == category.id }) {
                let currentSnapshot = CategorySnapshot(from: currentCategory)
                snapshot.restore(to: currentCategory)
                save()
                undoStack.append(UndoableAction.updateCategory(currentCategory, currentSnapshot))
            }
        }
    }

    func clearUndoHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
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
