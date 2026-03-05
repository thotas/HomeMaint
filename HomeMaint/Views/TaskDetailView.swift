import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: MaintenanceTask
    let taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    @State private var selectedCategory: Category?

    var category: Category? {
        task.getCategory(from: taskStore)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statusSection
                scheduleSection
                notesSection
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
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill((category?.color.swiftColor ?? .gray).opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: category?.icon ?? "tag.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(category?.color.swiftColor ?? .gray)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(task.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(category?.name ?? "Unknown")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background((category?.color.swiftColor ?? .gray).opacity(0.2))
                        .clipShape(Capsule())

                    Text(task.frequency.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
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
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                StatusCard(
                    title: "Status",
                    value: statusText,
                    icon: statusIcon,
                    color: statusColor
                )

                StatusCard(
                    title: "Time Remaining",
                    value: task.isOverdue ? "\(-task.daysUntilDue) days overdue" : "\(task.daysUntilDue) days",
                    icon: "clock",
                    color: task.isOverdue ? .red : .blue
                )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressGradient)
                        .frame(width: geometry.size.width * progress, height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                ScheduleRow(
                    label: "Last Completed",
                    date: task.lastCompleted,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Divider()
                    .background(Color.gray.opacity(0.3))

                ScheduleRow(
                    label: "Next Due",
                    date: task.nextDue,
                    icon: "calendar.badge.clock",
                    color: task.isOverdue ? .red : .blue
                )

                if task.lastCompleted != nil {
                    Divider()
                        .background(Color.gray.opacity(0.3))

                    HStack {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundStyle(.gray)

                        Spacer()

                        Text(task.frequency.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }

                Divider()
                    .background(Color.gray.opacity(0.3))

                HStack {
                    Text("Estimated Time")
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    Spacer()

                    Text("\(task.estimatedDuration) minutes")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(.white)

            if task.taskDescription.isEmpty && task.notes.isEmpty {
                Text("No notes added")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                if !task.taskDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.gray)

                        Text(task.taskDescription)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }

                if !task.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Notes")
                            .font(.caption)
                            .foregroundStyle(.gray)

                        Text(task.notes)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo.opacity(0.5))
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
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
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
                .foregroundStyle(.gray)

            Spacer()

            if let date = date {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(date, style: .date)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            } else {
                Text("Not completed yet")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }
}
