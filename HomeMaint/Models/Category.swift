import Foundation
import SwiftData
import SwiftUI

@Model
class Category: Identifiable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var colorRaw: String
    var sortOrder: Int
    var isActive: Bool
    var createdAt: Date

    var color: CategoryColor {
        get { CategoryColor(rawValue: colorRaw) ?? .indigo }
        set { colorRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: CategoryColor = .indigo,
        sortOrder: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorRaw = color.rawValue
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.createdAt = Date()
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum CategoryColor: String, Codable, CaseIterable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case mint = "Mint"
    case cyan = "Cyan"
    case blue = "Blue"
    case indigo = "Indigo"
    case purple = "Purple"
    case pink = "Pink"
    case brown = "Brown"
    case gray = "Gray"

    var swiftColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }

    var icon: String {
        switch self {
        case .red: return "flame.fill"
        case .orange: return "sun.max.fill"
        case .yellow: return "bolt.fill"
        case .green: return "leaf.fill"
        case .mint: return "sparkles"
        case .cyan: return "wind"
        case .blue: return "drop.fill"
        case .indigo: return "house.fill"
        case .purple: return "paintbrush.fill"
        case .pink: return "heart.fill"
        case .brown: return "tree.fill"
        case .gray: return "gearshape.fill"
        }
    }
}

// MARK: - Default Categories
extension Category {
    static var defaultCategories: [(name: String, icon: String, color: CategoryColor)] {
        [
            ("HVAC", "fan.fill", .cyan),
            ("Plumbing", "drop.fill", .blue),
            ("Electrical", "bolt.fill", .yellow),
            ("Exterior", "house.fill", .brown),
            ("Interior", "paintbrush.fill", .purple),
            ("Appliances", "washer.fill", .gray),
            ("Safety", "checkmark.shield.fill", .red),
            ("Yard", "leaf.fill", .green),
            ("Cleaning", "sparkles", .mint),
            ("Other", "tag.fill", .indigo)
        ]
    }

    static func insertDefaults(into context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        guard (try? context.fetch(descriptor))?.isEmpty ?? true else { return }

        for (index, data) in defaultCategories.enumerated() {
            let category = Category(
                name: data.name,
                icon: data.icon,
                color: data.color,
                sortOrder: index
            )
            context.insert(category)
        }

        try? context.save()
    }
}

// MARK: - Migration Helper
// For migrating from old enum-based categories
enum TaskCategory: String, Codable, CaseIterable {
    case hvac = "HVAC"
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case exterior = "Exterior"
    case interior = "Interior"
    case appliances = "Appliances"
    case safety = "Safety"
    case yard = "Yard"
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

    var color: CategoryColor {
        switch self {
        case .hvac: return .cyan
        case .plumbing: return .blue
        case .electrical: return .yellow
        case .exterior: return .brown
        case .interior: return .purple
        case .appliances: return .gray
        case .safety: return .red
        case .yard: return .green
        case .cleaning: return .mint
        case .other: return .indigo
        }
    }
}
