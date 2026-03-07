import Foundation
import SwiftData
import SwiftUI

enum DataExportError: LocalizedError {
    case exportFailed(String)
    case importFailed(String)
    case invalidFormat
    case noData

    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .importFailed(let message):
            return "Import failed: \(message)"
        case .invalidFormat:
            return "Invalid file format"
        case .noData:
            return "No data to export"
        }
    }
}

struct ExportedTask: Codable, Identifiable {
    var id: String
    var name: String
    var description: String
    var category: String
    var lastCompleted: Date?
    var nextDue: Date
    var frequency: String
    var notes: String
    var estimatedDuration: Int
    var isActive: Bool

    // Custom initializer for creating from MaintenanceTask
    static func from(task: MaintenanceTask, categoryName: String?) -> ExportedTask {
        return ExportedTask(
            id: task.id.uuidString,
            name: task.name,
            description: task.taskDescription,
            category: categoryName ?? "Other",
            lastCompleted: task.lastCompleted,
            nextDue: task.nextDue,
            frequency: task.frequencyRaw,
            notes: task.notes,
            estimatedDuration: task.estimatedDuration,
            isActive: task.isActive
        )
    }
}

@Observable
class DataExportManager {
    static let shared = DataExportManager()

    private init() {}

    // MARK: - CSV Export

    func exportToCSV(tasks: [MaintenanceTask], categories: [Category]) throws -> URL {
        guard !tasks.isEmpty else {
            throw DataExportError.noData
        }

        // Create category lookup by ID
        var categoryLookup: [UUID: String] = [:]
        for category in categories {
            categoryLookup[category.id] = category.name
        }

        // Build CSV content
        var csvContent = "name,category,lastCompleted,nextDue,frequency,notes,description,estimatedDuration,isActive\n"

        let dateFormatter = ISO8601DateFormatter()

        for task in tasks {
            let categoryName = task.categoryID.flatMap { categoryLookup[$0] } ?? "Other"
            let lastCompleted = task.lastCompleted.map { dateFormatter.string(from: $0) } ?? ""
            let nextDue = dateFormatter.string(from: task.nextDue)

            // Escape fields that might contain commas or quotes
            let escapedName = escapeCSVField(task.name)
            let escapedCategory = escapeCSVField(categoryName)
            let escapedNotes = escapeCSVField(task.notes)
            let escapedDescription = escapeCSVField(task.taskDescription)

            csvContent += "\(escapedName),\(escapedCategory),\(lastCompleted),\(nextDue),\(task.frequencyRaw),\(escapedNotes),\(escapedDescription),\(task.estimatedDuration),\(task.isActive)\n"
        }

        // Write to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "HomeMaint_Export_\(dateString()).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw DataExportError.exportFailed(error.localizedDescription)
        }
    }

    // MARK: - CSV Import

    func importFromCSV(url: URL, categories: [Category]) throws -> [ExportedTask] {
        guard url.startAccessingSecurityScopedResource() else {
            throw DataExportError.importFailed("Cannot access file")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw DataExportError.invalidFormat
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw DataExportError.invalidFormat
        }

        // Parse header
        let header = parseCSVLine(lines[0])
        guard header.contains("name") && header.contains("frequency") else {
            throw DataExportError.invalidFormat
        }

        var importedTasks: [ExportedTask] = []

        for line in lines.dropFirst() where !line.isEmpty {
            let fields = parseCSVLine(line)

            guard fields.count >= 5 else { continue }

            let name = fields[0]
            let category = fields[1]
            let lastCompletedStr = fields[2]
            let nextDueStr = fields[3]
            let frequency = fields[4]
            let notes = fields.count > 5 ? fields[5] : ""
            let description = fields.count > 6 ? fields[6] : ""
            let estimatedDuration = fields.count > 7 ? Int(fields[6]) ?? 30 : 30
            let isActive = fields.count > 8 ? fields[7].lowercased() == "true" : true

            let dateFormatter = ISO8601DateFormatter()
            let lastCompleted = lastCompletedStr.isEmpty ? nil : dateFormatter.date(from: lastCompletedStr)
            let nextDue = dateFormatter.date(from: nextDueStr) ?? Date()

            var task = ExportedTask(
                id: UUID().uuidString,
                name: name,
                description: description,
                category: category,
                lastCompleted: lastCompleted,
                nextDue: nextDue,
                frequency: frequency,
                notes: notes,
                estimatedDuration: estimatedDuration,
                isActive: isActive
            )
            task.id = UUID().uuidString
            importedTasks.append(task)
        }

        return importedTasks
    }

    func importTasks(from exportedTasks: [ExportedTask], categoryLookup: [String: UUID], taskStore: TaskStore) -> (imported: Int, skipped: Int) {
        var importedCount = 0
        var skippedCount = 0

        for exportedTask in exportedTasks {
            let categoryID = categoryLookup[exportedTask.category] ?? categoryLookup["Other"]

            guard let frequency = TaskFrequency(rawValue: exportedTask.frequency) else {
                skippedCount += 1
                continue
            }

            let task = MaintenanceTask(
                name: exportedTask.name,
                taskDescription: exportedTask.description,
                categoryID: categoryID,
                frequency: frequency,
                lastCompleted: exportedTask.lastCompleted,
                isActive: exportedTask.isActive,
                notes: exportedTask.notes,
                estimatedDuration: exportedTask.estimatedDuration
            )

            // Override nextDue with imported value
            task.nextDue = exportedTask.nextDue

            taskStore.addTask(task)
            importedCount += 1
        }

        return (importedCount, skippedCount)
    }

    // MARK: - Helpers

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false

        var i = line.startIndex
        while i < line.endIndex {
            let char = line[i]

            if inQuotes {
                if char == "\"" {
                    let nextIndex = line.index(after: i)
                    if nextIndex < line.endIndex && line[nextIndex] == "\"" {
                        currentField.append("\"")
                        i = nextIndex
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(currentField)
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            }

            i = line.index(after: i)
        }

        fields.append(currentField)
        return fields
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}
