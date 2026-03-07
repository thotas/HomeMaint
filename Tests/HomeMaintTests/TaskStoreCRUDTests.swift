import XCTest
import SwiftData
@testable import HomeMaint

@MainActor
final class TaskStoreCRUDTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var taskStore: TaskStore!

    override func setUp() async throws {
        let schema = Schema([MaintenanceTask.self, Category.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = modelContainer.mainContext
        taskStore = TaskStore()
        taskStore.setContext(modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        taskStore = nil
    }

    // MARK: - Add Task Tests

    func testAddTaskInsertsTaskIntoContext() {
        let initialCount = taskStore.fetchAllTasks().count

        let task = MaintenanceTask(
            name: "New Test Task",
            frequency: .monthly
        )
        taskStore.addTask(task)

        let finalCount = taskStore.fetchAllTasks().count
        XCTAssertEqual(finalCount, initialCount + 1)
    }

    func testAddTaskAppearsInFetchedTasks() {
        let task = MaintenanceTask(
            name: "Unique Test Task Name",
            frequency: .weekly
        )
        taskStore.addTask(task)

        let fetchedTasks = taskStore.fetchAllTasks()
        XCTAssertTrue(fetchedTasks.contains { $0.name == "Unique Test Task Name" })
    }

    func testAddTaskWithCategory() {
        let category = Category(name: "Test Category", icon: "star.fill", color: .blue)
        taskStore.addCategory(category)

        let task = MaintenanceTask(
            name: "Task with Category",
            categoryID: category.id,
            frequency: .monthly
        )
        taskStore.addTask(task)

        let fetchedTask = taskStore.fetchAllTasks().first { $0.name == "Task with Category" }
        XCTAssertNotNil(fetchedTask)
        XCTAssertEqual(fetchedTask?.categoryID, category.id)
    }

    // MARK: - Update Task Tests

    func testUpdateTaskChangesTaskProperties() {
        let task = MaintenanceTask(
            name: "Original Name",
            frequency: .monthly
        )
        taskStore.addTask(task)

        // Update the task
        task.name = "Updated Name"
        task.notes = "Some notes"
        taskStore.updateTask(task)

        let fetchedTask = taskStore.fetchAllTasks().first { $0.id == task.id }
        XCTAssertEqual(fetchedTask?.name, "Updated Name")
        XCTAssertEqual(fetchedTask?.notes, "Some notes")
    }

    func testUpdateTaskRecalculatesNextDue() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: nil
        )
        taskStore.addTask(task)

        // Mark as completed - this should update next due
        task.markAsCompleted()
        taskStore.updateTask(task)

        let fetchedTask = taskStore.fetchAllTasks().first { $0.id == task.id }
        XCTAssertNotNil(fetchedTask?.lastCompleted)
    }

    // MARK: - Delete Task Tests

    func testDeleteTaskRemovesTaskFromContext() {
        let task = MaintenanceTask(
            name: "Task to Delete",
            frequency: .monthly
        )
        taskStore.addTask(task)
        let taskID = task.id

        taskStore.deleteTask(task)

        let fetchedTask = taskStore.fetchAllTasks().first { $0.id == taskID }
        XCTAssertNil(fetchedTask)
    }

    func testDeleteTaskReducesTaskCount() {
        let task = MaintenanceTask(
            name: "Another Task",
            frequency: .weekly
        )
        taskStore.addTask(task)
        let initialCount = taskStore.fetchAllTasks().count

        taskStore.deleteTask(task)

        let finalCount = taskStore.fetchAllTasks().count
        XCTAssertEqual(finalCount, initialCount - 1)
    }

    // MARK: - Mark Complete Tests

    func testMarkTaskCompleteSetsLastCompleted() {
        let task = MaintenanceTask(
            name: "Task to Complete",
            frequency: .monthly
        )
        taskStore.addTask(task)

        taskStore.markTaskComplete(task)

        let fetchedTask = taskStore.fetchAllTasks().first { $0.id == task.id }
        XCTAssertNotNil(fetchedTask?.lastCompleted)
    }

    func testMarkTaskCompleteUpdatesNextDue() {
        let task = MaintenanceTask(
            name: "Task to Complete",
            frequency: .monthly,
            lastCompleted: nil
        )
        let originalNextDue = task.nextDue
        taskStore.addTask(task)

        taskStore.markTaskComplete(task)

        let fetchedTask = taskStore.fetchAllTasks().first { $0.id == task.id }
        XCTAssertTrue(fetchedTask!.nextDue > originalNextDue)
    }

    // MARK: - Toggle Active Tests

    func testToggleTaskActiveChangesIsActive() {
        let task = MaintenanceTask(
            name: "Toggle Test",
            frequency: .monthly,
            isActive: true
        )
        taskStore.addTask(task)

        XCTAssertEqual(task.isActive, true)

        taskStore.toggleTaskActive(task)

        XCTAssertEqual(task.isActive, false)
    }

    // MARK: - Fetch Tests

    func testFetchActiveTasksOnlyReturnsActive() {
        let activeTask = MaintenanceTask(name: "Active", frequency: .monthly, isActive: true)
        let inactiveTask = MaintenanceTask(name: "Inactive", frequency: .monthly, isActive: false)

        taskStore.addTask(activeTask)
        taskStore.addTask(inactiveTask)

        let activeTasks = taskStore.fetchActiveTasks()

        XCTAssertTrue(activeTasks.contains { $0.name == "Active" })
        XCTAssertFalse(activeTasks.contains { $0.name == "Inactive" })
    }

    func testFetchOverdueTasksReturnsOnlyOverdue() {
        let overdueTask = MaintenanceTask(name: "Overdue", frequency: .monthly, lastCompleted: nil)
        overdueTask.nextDue = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

        let futureTask = MaintenanceTask(name: "Future", frequency: .monthly, lastCompleted: nil)
        futureTask.nextDue = Calendar.current.date(byAdding: .day, value: 10, to: Date())!

        taskStore.addTask(overdueTask)
        taskStore.addTask(futureTask)

        let overdueTasks = taskStore.fetchOverdueTasks()

        XCTAssertTrue(overdueTasks.contains { $0.name == "Overdue" })
        XCTAssertFalse(overdueTasks.contains { $0.name == "Future" })
    }

    func testFetchUpcomingTasksReturnsTasksDueWithinPeriod() {
        let task1 = MaintenanceTask(name: "Due in 3 days", frequency: .monthly)
        task1.nextDue = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        let task2 = MaintenanceTask(name: "Due in 10 days", frequency: .monthly)
        task2.nextDue = Calendar.current.date(byAdding: .day, value: 10, to: Date())!

        taskStore.addTask(task1)
        taskStore.addTask(task2)

        let upcomingTasks = taskStore.fetchUpcomingTasks(days: 7)

        XCTAssertTrue(upcomingTasks.contains { $0.name == "Due in 3 days" })
        XCTAssertFalse(upcomingTasks.contains { $0.name == "Due in 10 days" })
    }

    // MARK: - Category Tests

    func testFetchTasksByCategoryReturnsCorrectTasks() {
        let category = Category(name: "TestCategory", icon: "star.fill", color: .blue)
        taskStore.addCategory(category)

        let task1 = MaintenanceTask(name: "Task 1", categoryID: category.id, frequency: .monthly)
        let task2 = MaintenanceTask(name: "Task 2", categoryID: category.id, frequency: .monthly)
        let task3 = MaintenanceTask(name: "Task 3", frequency: .monthly)

        taskStore.addTask(task1)
        taskStore.addTask(task2)
        taskStore.addTask(task3)

        let categoryTasks = taskStore.fetchTasksByCategory(category)

        XCTAssertEqual(categoryTasks.count, 2)
        XCTAssertTrue(categoryTasks.allSatisfy { $0.categoryID == category.id })
    }
}
