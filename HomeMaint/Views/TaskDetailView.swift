import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: MaintenanceTask
    let taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Status Section
                statusSection

                // Schedule Section
                scheduleSection

                // Notes Section
                notesSection

                // Actions
                actionsSection
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label("Edit Task", systemImage: "pencil")
                    }

                    Button(action: { taskStore.toggleTaskActive(task) }) {
                        Label(task.isActive ? "Deactivate" : "Activate", systemImage: task.isActive ? "pause.circle" : "play.circle")
                    }

                    Divider()

                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Task", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Task?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                taskStore.deleteTask(task)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task, taskStore: taskStore) {
                isEditing = false
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 20) {
            // Large Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: task.category.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(task.name)
                    .font(.title2.bold())

                HStack(spacing: 8) {
                    Text(task.category.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.2))
                        .clipShape(Capsule())

                    Text(task.frequency.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status")
                .font(.headline)

            HStack(spacing: 16) {
                // Current Status
                StatusCard(
                    title: "Status",
                    value: statusText,
                    icon: statusIcon,
                    color: statusColor
                )

                // Days Remaining
                StatusCard(
                    title: "Time Remaining",
                    value: task.isOverdue ? "\(-task.daysUntilDue) days overdue" : "\(task.daysUntilDue) days",
                    icon: "clock",
                    color: task.isOverdue ? .red : .blue
                )
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to next due date")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressGradient)
                            .frame(width: geometry.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule")
                .font(.headline)

            VStack(spacing: 12) {
                ScheduleRow(
                    label: "Last Completed",
                    date: task.lastCompleted,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Divider()

                ScheduleRow(
                    label: "Next Due",
                    date: task.nextDue,
                    icon: "calendar.badge.clock",
                    color: task.isOverdue ? .red : .blue
                )

                if task.lastCompleted != nil {
                    Divider()

                    HStack {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(task.frequency.rawValue)
                            .font(.subheadline)
                    }
                }

                Divider()

                HStack {
                    Text("Estimated Time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(task.estimatedDuration) minutes")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)

            if task.taskDescription.isEmpty && task.notes.isEmpty {
                Text("No notes added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                if !task.taskDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(task.taskDescription)
                            .font(.subheadline)
                    }
                }

                if !task.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(task.notes)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                taskStore.markTaskComplete(task)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Complete")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button(action: {
                isEditing = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Task")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Computed Properties

    private var progress: CGFloat {
        let totalDays = Double(task.frequency.days)
        let daysRemaining = Double(task.daysUntilDue)
        let progress = 1.0 - (daysRemaining / totalDays)
        return max(0, min(1, CGFloat(progress)))
    }

    private var progressGradient: LinearGradient {
        if task.isOverdue {
            return LinearGradient(colors: [.red], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(
            colors: [.green, .yellow, .orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var statusText: String {
        switch task.urgency {
        case .overdue: return "Overdue"
        case .dueSoon: return "Due Soon"
        case .upcoming: return "Upcoming"
        case .normal: return "On Track"
        }
    }

    private var statusIcon: String {
        switch task.urgency {
        case .overdue: return "exclamationmark.triangle.fill"
        case .dueSoon: return "clock.fill"
        case .upcoming: return "calendar"
        case .normal: return "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch task.urgency {
        case .overdue: return .red
        case .dueSoon: return .orange
        case .upcoming: return .yellow
        case .normal: return .green
        }
    }

    private var categoryColor: Color {
        switch task.category {
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

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScheduleRow: View {
    let label: String
    let date: Date?
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let date = date {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(date, style: .date)
                        .font(.subheadline.bold())

                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Not completed yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
