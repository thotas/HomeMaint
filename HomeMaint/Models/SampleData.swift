import Foundation
import SwiftData

enum SampleData {
    static let tasks: [(name: String, description: String, category: TaskCategory, frequency: TaskFrequency, lastCompleted: Date?, duration: Int)] = [
        // HVAC
        ("Change HVAC Filter", "Replace the air filter in the main HVAC system", .hvac, .monthly, daysAgo(25), 15),
        ("Clean Air Vents", "Vacuum and clean all air vent covers", .hvac, .quarterly, daysAgo(80), 45),
        ("Service AC Unit", "Professional AC unit inspection and service", .hvac, .annual, daysAgo(200), 120),
        ("Check Thermostat", "Test and calibrate thermostat settings", .hvac, .biannual, daysAgo(100), 10),

        // Plumbing
        ("Clean Garbage Disposal", "Clean and deodorize the garbage disposal", .plumbing, .monthly, daysAgo(35), 10),
        ("Check for Leaks", "Inspect under sinks and around toilets for leaks", .plumbing, .monthly, daysAgo(10), 20),
        ("Drain Water Heater", "Flush and drain the water heater tank", .plumbing, .annual, daysAgo(300), 60),
        ("Clean Showerheads", "Remove mineral buildup from showerheads", .plumbing, .quarterly, daysAgo(95), 15),

        // Electrical
        ("Test Smoke Detectors", "Test all smoke and CO detectors", .safety, .monthly, daysAgo(5), 10),
        ("Replace Smoke Detector Batteries", "Change batteries in all smoke detectors", .safety, .biannual, daysAgo(150), 15),
        ("Check GFCI Outlets", "Test all GFCI outlets", .electrical, .monthly, daysAgo(12), 10),
        ("Inspect Extension Cords", "Check for damage and proper storage", .electrical, .quarterly, daysAgo(70), 5),

        // Exterior
        ("Clean Gutters", "Remove leaves and debris from gutters", .exterior, .biannual, daysAgo(180), 90),
        ("Inspect Roof", "Check for damaged shingles or leaks", .exterior, .annual, daysAgo(220), 30),
        ("Power Wash Siding", "Clean exterior walls with power washer", .exterior, .annual, daysAgo(380), 180),
        ("Check Caulking", "Inspect and repair window/door caulking", .exterior, .annual, daysAgo(250), 60),
        ("Paint Touch-ups", "Touch up exterior paint as needed", .exterior, .biennial, daysAgo(400), 240),

        // Interior
        ("Deep Clean Carpets", "Shampoo and deep clean all carpets", .cleaning, .biannual, daysAgo(170), 180),
        ("Clean Dryer Vent", "Clean lint from dryer vent pipe", .safety, .quarterly, daysAgo(85), 30),
        ("Vacuum Refrigerator Coils", "Clean dust from fridge coils", .appliances, .quarterly, daysAgo(60), 15),
        ("Clean Range Hood Filter", "Degrease and clean range hood filter", .appliances, .monthly, daysAgo(28), 20),

        // Appliances
        ("Descale Coffee Maker", "Run descaling solution through coffee maker", .appliances, .monthly, daysAgo(32), 30),
        ("Clean Dishwasher Filter", "Remove and clean dishwasher filter", .appliances, .monthly, daysAgo(40), 10),
        ("Clean Washing Machine", "Run cleaning cycle on washing machine", .appliances, .monthly, daysAgo(15), 5),
        ("Service Garage Door", "Lubricate and inspect garage door mechanism", .exterior, .annual, daysAgo(330), 45),

        // Yard
        ("Fertilize Lawn", "Apply seasonal fertilizer", .yard, .quarterly, daysAgo(100), 60),
        ("Aerate Lawn", "Aerate the lawn for better water absorption", .yard, .annual, daysAgo(280), 120),
        ("Mulch Garden Beds", "Add fresh mulch to garden beds", .yard, .annual, daysAgo(310), 180),
        ("Prune Trees", "Trim dead branches and shape trees", .yard, .annual, daysAgo(200), 240),
        ("Winterize Sprinklers", "Blow out and winterize sprinkler system", .yard, .annual, daysAgo(150), 90),

        // Safety
        ("Check Fire Extinguishers", "Verify pressure and expiration dates", .safety, .annual, daysAgo(290), 10),
        ("Review Emergency Kit", "Check and refresh emergency supplies", .safety, .biannual, daysAgo(160), 30),
        ("Test Security System", "Test all sensors and cameras", .safety, .monthly, daysAgo(8), 15),
        ("Inspect Attic", "Check for pests, leaks, or insulation issues", .interior, .annual, daysAgo(270), 45),
    ]

    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    static func insertSampleData(context: ModelContext) {
        let descriptor = FetchDescriptor<MaintenanceTask>()
        guard (try? context.fetch(descriptor))?.isEmpty ?? true else { return }

        for taskData in tasks {
            let task = MaintenanceTask(
                name: taskData.name,
                taskDescription: taskData.description,
                category: taskData.category,
                frequency: taskData.frequency,
                lastCompleted: taskData.lastCompleted,
                estimatedDuration: taskData.duration
            )
            context.insert(task)
        }

        try? context.save()
    }
}
