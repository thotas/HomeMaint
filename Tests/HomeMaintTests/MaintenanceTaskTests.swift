import XCTest
import SwiftData
@testable import HomeMaint

final class MaintenanceTaskTests: XCTestCase {
    var modelContainer: ModelContainer!

    override func setUp() async throws {
        let schema = Schema([MaintenanceTask.self, Category.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
    }

    override func tearDown() {
        modelContainer = nil
    }

    // MARK: - Urgency Tests

    func testUrgencyIsOverdueWhenPastDueDate() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        // Set nextDue to yesterday
        task.nextDue = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        XCTAssertEqual(task.urgency, .overdue)
        XCTAssertTrue(task.isOverdue)
    }

    func testUrgencyIsDueSoonWhenWithinThreeDays() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        // Set nextDue to 2 days from now
        task.nextDue = Calendar.current.date(byAdding: .day, value: 2, to: Date())!

        XCTAssertEqual(task.urgency, .dueSoon)
        XCTAssertFalse(task.isOverdue)
    }

    func testUrgencyIsUpcomingWhenWithinSevenDays() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        // Set nextDue to 5 days from now
        task.nextDue = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        XCTAssertEqual(task.urgency, .upcoming)
        XCTAssertFalse(task.isOverdue)
    }

    func testUrgencyIsNormalWhenMoreThanSevenDaysAway() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        // Set nextDue to 10 days from now
        task.nextDue = Calendar.current.date(byAdding: .day, value: 10, to: Date())!

        XCTAssertEqual(task.urgency, .normal)
        XCTAssertFalse(task.isOverdue)
    }

    func testUrgencyPriorityOrdering() {
        XCTAssertEqual(TaskUrgency.overdue.priority, 0)
        XCTAssertEqual(TaskUrgency.dueSoon.priority, 1)
        XCTAssertEqual(TaskUrgency.upcoming.priority, 2)
        XCTAssertEqual(TaskUrgency.normal.priority, 3)
    }

    // MARK: - Next Due Date Tests

    func testNextDueDateCalculatedFromLastCompletedForWeekly() {
        let lastCompleted = Date()
        let nextDue = MaintenanceTask.calculateNextDue(from: lastCompleted, frequency: .weekly)

        let expectedNextDue = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: lastCompleted)!

        XCTAssertEqual(Calendar.current.isDate(nextDue, inSameDayAs: expectedNextDue), true)
    }

    func testNextDueDateCalculatedFromLastCompletedForMonthly() {
        let lastCompleted = Date()
        let nextDue = MaintenanceTask.calculateNextDue(from: lastCompleted, frequency: .monthly)

        let expectedNextDue = Calendar.current.date(byAdding: .month, value: 1, to: lastCompleted)!

        XCTAssertEqual(Calendar.current.isDate(nextDue, inSameDayAs: expectedNextDue), true)
    }

    func testNextDueDateCalculatedFromLastCompletedForAnnual() {
        let lastCompleted = Date()
        let nextDue = MaintenanceTask.calculateNextDue(from: lastCompleted, frequency: .annual)

        let expectedNextDue = Calendar.current.date(byAdding: .year, value: 1, to: lastCompleted)!

        XCTAssertEqual(Calendar.current.isDate(nextDue, inSameDayAs: expectedNextDue), true)
    }

    func testNextDueDateUsesCurrentDateWhenNoLastCompleted() {
        let nextDue = MaintenanceTask.calculateNextDue(from: nil, frequency: .monthly)

        let expectedNextDue = Calendar.current.date(byAdding: .month, value: 1, to: Date())!

        XCTAssertEqual(Calendar.current.isDate(nextDue, inSameDayAs: expectedNextDue), true)
    }

    func testUpdateNextDueRecalculatesNextDueDate() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        let originalNextDue = task.nextDue

        // Mark as completed to update next due date
        task.markAsCompleted()

        XCTAssertNotEqual(task.nextDue, originalNextDue)
        XCTAssertTrue(task.nextDue > originalNextDue)
    }

    // MARK: - Days Until Due Tests

    func testDaysUntilDueIsNegativeWhenOverdue() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        task.nextDue = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

        XCTAssertTrue(task.daysUntilDue < 0)
    }

    func testDaysUntilDueIsZeroWhenDueToday() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        task.nextDue = Calendar.current.startOfDay(for: Date())

        XCTAssertEqual(task.daysUntilDue, 0)
    }

    func testDaysUntilDueIsPositiveWhenInFuture() {
        let task = MaintenanceTask(
            name: "Test Task",
            frequency: .monthly,
            lastCompleted: Date()
        )

        task.nextDue = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        XCTAssertEqual(task.daysUntilDue, 5)
    }

    // MARK: - Task Frequency Tests

    func testWeeklyFrequencyHasCorrectDays() {
        XCTAssertEqual(TaskFrequency.weekly.days, 7)
    }

    func testMonthlyFrequencyHasCorrectDays() {
        XCTAssertEqual(TaskFrequency.monthly.days, 30)
    }

    func testAnnualFrequencyHasCorrectDays() {
        XCTAssertEqual(TaskFrequency.annual.days, 365)
    }

    func testWeeklyFrequencyDateComponent() {
        XCTAssertEqual(TaskFrequency.weekly.dateComponent, .weekOfYear)
    }

    func testAnnualFrequencyDateComponent() {
        XCTAssertEqual(TaskFrequency.annual.dateComponent, .year)
    }
}
