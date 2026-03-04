import Foundation
import SwiftData

@Model
class MaintenanceTask {
    var id: UUID
    var name: String
    var taskDescription: String
    var categoryRaw: String
    var frequencyRaw: String
    var lastCompleted: Date?
    var nextDue: Date
    var createdAt: Date
    var isActive: Bool
    var notes: String
    var estimatedDuration: Int // in minutes

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var frequency: TaskFrequency {
        get { TaskFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        taskDescription: String = "",
        category: TaskCategory,
        frequency: TaskFrequency,
        lastCompleted: Date? = nil,
        isActive: Bool = true,
        notes: String = "",
        estimatedDuration: Int = 30
    ) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.categoryRaw = category.rawValue
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
        return .normal }
}

enum TaskCategory: String, Codable, CaseIterable {
    case hvac = "HVAC"
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case exterior = "Exterior"
    case interior = "Interior"
    case appliances = "Appliances"
    case safety = "Safety"
    case yard = "Yard & Garden"
    case cleaning = "Cleaning"
    case other = "Other"

    var icon: String {
        switch self {
        case .hvac: return "fan.fill"
        case .plumbing: return "drop.fill"
        case .electrical: return "bolt.fill"
        case .exterior: return "house.fill"
        case .interior: return "paintbrush.fill"
        case .appliances: return "washer.fill"
        case .safety: return "checkmark.shield.fill"
        case .yard: return "leaf.fill"
        case .cleaning: return "sparkles"
        case .other: return "tag.fill"
        }
    }

    var color: String {
        switch self {
        case .hvac: return "cyan"
        case .plumbing: return "blue"
        case .electrical: return "yellow"
        case .exterior: return "brown"
        case .interior: return "purple"
        case .appliances: return "gray"
        case .safety: return "red"
        case .yard: return "green"
        case .cleaning: return "mint"
        case .other: return "indigo"
        }
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

    var color: String {
        switch self {
        case .overdue: return "red"
        case .dueSoon: return "orange"
        case .upcoming: return "yellow"
        case .normal: return "green"
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
