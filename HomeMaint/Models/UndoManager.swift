import Foundation
import SwiftData

// MARK: - Undoable Action

enum UndoableAction {
    case deleteTask(MaintenanceTask)
    case deleteCategory(Category, [MaintenanceTask])
    case updateTask(MaintenanceTask, TaskSnapshot)
    case updateCategory(Category, CategorySnapshot)

    var actionName: String {
        switch self {
        case .deleteTask:
            return "Delete Task"
        case .deleteCategory:
            return "Delete Category"
        case .updateTask:
            return "Update Task"
        case .updateCategory:
            return "Update Category"
        }
    }
}

// MARK: - Snapshots for restoring state

struct TaskSnapshot {
    let name: String
    let taskDescription: String
    let categoryID: UUID?
    let frequencyRaw: String
    let lastCompleted: Date?
    let nextDue: Date
    let isActive: Bool
    let notes: String
    let estimatedDuration: Int

    init(from task: MaintenanceTask) {
        self.name = task.name
        self.taskDescription = task.taskDescription
        self.categoryID = task.categoryID
        self.frequencyRaw = task.frequencyRaw
        self.lastCompleted = task.lastCompleted
        self.nextDue = task.nextDue
        self.isActive = task.isActive
        self.notes = task.notes
        self.estimatedDuration = task.estimatedDuration
    }

    func restore(to task: MaintenanceTask) {
        task.name = name
        task.taskDescription = taskDescription
        task.categoryID = categoryID
        task.frequencyRaw = frequencyRaw
        task.lastCompleted = lastCompleted
        task.nextDue = nextDue
        task.isActive = isActive
        task.notes = notes
        task.estimatedDuration = estimatedDuration
    }
}

struct CategorySnapshot {
    let name: String
    let icon: String
    let colorRaw: String
    let sortOrder: Int
    let isActive: Bool

    init(from category: Category) {
        self.name = category.name
        self.icon = category.icon
        self.colorRaw = category.colorRaw
        self.sortOrder = category.sortOrder
        self.isActive = category.isActive
    }

    func restore(to category: Category) {
        category.name = name
        category.icon = icon
        category.colorRaw = colorRaw
        category.sortOrder = sortOrder
        category.isActive = isActive
    }
}
