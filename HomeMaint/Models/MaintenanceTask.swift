import Foundation
import SwiftData
import SwiftUI

@Model
class MaintenanceTask {
    var id: UUID
    var name: String
    var taskDescription: String
    var categoryID: UUID?
    var frequencyRaw: String
    var lastCompleted: Date?
    var nextDue: Date
    var createdAt: Date
    var isActive: Bool
    var notes: String
    var estimatedDuration: Int // in minutes

    var frequency: TaskFrequency {
        get { TaskFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        taskDescription: String = "",
        categoryID: UUID? = nil,
        frequency: TaskFrequency,
        lastCompleted: Date? = nil,
        isActive: Bool = true,
        notes: String = "",
        estimatedDuration: Int = 30
    ) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.categoryID = categoryID
        self.frequencyRaw = frequency.rawValue
        self.lastCompleted = lastCompleted
        self.isActive = isActive
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.createdAt = Date()
        self.nextDue = Self.calculateNextDue(from: lastCompleted, frequency: frequency)
    }

    static func calculateNextDue(from lastCompleted: Date?, frequency: TaskFrequency) -> Date {
        let baseDate = lastCompleted ?? Date()
        return Calendar.current.date(byAdding: frequency.dateComponent, value: frequency.interval, to: baseDate) ?? Date()
    }

    func updateNextDue() {
        nextDue = Self.calculateNextDue(from: lastCompleted, frequency: frequency)
    }

    func markAsCompleted() {
        lastCompleted = Date()
        updateNextDue()
    }

    var isOverdue: Bool {
        return Date() > nextDue
    }

    var daysUntilDue: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: nextDue)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDue)
        return components.day ?? 0
    }

    var urgency: TaskUrgency {
        if isOverdue { return .overdue }
        if daysUntilDue <= 3 { return .dueSoon }
        if daysUntilDue <= 7 { return .upcoming }
        return .normal
    }

    // Get category from store
    func getCategory(from store: TaskStore) -> Category? {
        guard let categoryID = categoryID else { return nil }
        return store.fetchCategory(by: categoryID)
    }
}

enum TaskFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case biannual = "Bi-annual"
    case annual = "Annual"
    case biennial = "Every 2 Years"

    var interval: Int {
        switch self {
        case .weekly: return 1
        case .biweekly: return 2
        case .monthly: return 1
        case .quarterly: return 3
        case .biannual: return 6
        case .annual: return 1
        case .biennial: return 2
        }
    }

    var dateComponent: Calendar.Component {
        switch self {
        case .weekly, .biweekly: return .weekOfYear
        case .monthly, .quarterly, .biannual: return .month
        case .annual, .biennial: return .year
        }
    }

    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .biannual: return 180
        case .annual: return 365
        case .biennial: return 730
        }
    }
}

enum TaskUrgency: String, CaseIterable {
    case overdue = "Overdue"
    case dueSoon = "Due Soon"
    case upcoming = "Upcoming"
    case normal = "Normal"

    var color: Color {
        switch self {
        case .overdue: return .red
        case .dueSoon: return .orange
        case .upcoming: return .yellow
        case .normal: return .green
        }
    }

    var priority: Int {
        switch self {
        case .overdue: return 0
        case .dueSoon: return 1
        case .upcoming: return 2
        case .normal: return 3
        }
    }
}
