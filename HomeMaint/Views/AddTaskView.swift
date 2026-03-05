import SwiftUI

struct AddTaskView: View {
    let taskStore: TaskStore
    let onSave: (MaintenanceTask) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: Category?
    @State private var selectedFrequency: TaskFrequency = .monthly
    @State private var lastCompleted: Date?
    @State private var hasLastCompleted = false
    @State private var estimatedDuration = 30
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                Form {
                    Section("Task Details") {
                        TextField("Task Name", text: $name)
                            .font(.body)
                            .foregroundStyle(.white)

                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(.white)
                    }

                    Section("Category") {
                        CategoryPicker(
                            taskStore: taskStore,
                            selectedCategory: $selectedCategory
                        )
                    }

                    Section("Frequency") {
                        Picker("How Often", selection: $selectedFrequency) {
                            ForEach(TaskFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue)
                                    .tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            Text("Estimated Duration")
                            Spacer()
                            Text("\(estimatedDuration) min")
                                .foregroundStyle(.gray)
                        }

                        Slider(value: .init(
                            get: { Double(estimatedDuration) },
                            set: { estimatedDuration = Int($0) }
                        ), in: 5...240, step: 5)
                    }

                    Section("Schedule") {
                        Toggle("Already Completed", isOn: $hasLastCompleted)

                        if hasLastCompleted {
                            DatePicker(
                                "Last Completed",
                                selection: .init(
                                    get: { lastCompleted ?? Date() },
                                    set: { lastCompleted = $0 }
                                ),
                                displayedComponents: .date
                            )
                        }
                    }

                    Section("Notes") {
                        TextField("Additional notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(.white)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func saveTask() {
        let task = MaintenanceTask(
            name: name,
            taskDescription: description,
            categoryID: selectedCategory?.id,
            frequency: selectedFrequency,
            lastCompleted: hasLastCompleted ? lastCompleted : nil,
            notes: notes,
            estimatedDuration: estimatedDuration
        )
        onSave(task)
    }
}

struct CategoryPicker: View {
    let taskStore: TaskStore
    @Binding var selectedCategory: Category?

    var categories: [Category] {
        taskStore.fetchActiveCategories()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
            ForEach(categories) { category in
                Button {
                    selectedCategory = category
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCategory?.id == category.id ? category.color.swiftColor : category.color.swiftColor.opacity(0.2))
                                .frame(height: 50)

                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundStyle(selectedCategory?.id == category.id ? .white : category.color.swiftColor)
                        }

                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(selectedCategory?.id == category.id ? category.color.swiftColor : .white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EditTaskView: View {
    @Bindable var task: MaintenanceTask
    let taskStore: TaskStore
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var selectedCategory: Category?
    @State private var selectedFrequency: TaskFrequency
    @State private var estimatedDuration: Int
    @State private var notes: String
    @State private var hasLastCompleted: Bool
    @State private var lastCompleted: Date?

    init(task: MaintenanceTask, taskStore: TaskStore, onComplete: @escaping () -> Void) {
        self.task = task
        self.taskStore = taskStore
        self.onComplete = onComplete

        _name = State(initialValue: task.name)
        _description = State(initialValue: task.taskDescription)
        _selectedCategory = State(initialValue: task.getCategory(from: taskStore))
        _selectedFrequency = State(initialValue: task.frequency)
        _estimatedDuration = State(initialValue: task.estimatedDuration)
        _notes = State(initialValue: task.notes)
        _hasLastCompleted = State(initialValue: task.lastCompleted != nil)
        _lastCompleted = State(initialValue: task.lastCompleted)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                Form {
                    Section("Task Details") {
                        TextField("Task Name", text: $name)
                            .font(.body)
                            .foregroundStyle(.white)

                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(.white)
                    }

                    Section("Category") {
                        CategoryPicker(
                            taskStore: taskStore,
                            selectedCategory: $selectedCategory
                        )
                    }

                    Section("Frequency") {
                        Picker("How Often", selection: $selectedFrequency) {
                            ForEach(TaskFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue)
                                    .tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            Text("Estimated Duration")
                            Spacer()
                            Text("\(estimatedDuration) min")
                                .foregroundStyle(.gray)
                        }

                        Slider(value: .init(
                            get: { Double(estimatedDuration) },
                            set: { estimatedDuration = Int($0) }
                        ), in: 5...240, step: 5)
                    }

                    Section("Schedule") {
                        Toggle("Already Completed", isOn: $hasLastCompleted)

                        if hasLastCompleted {
                            DatePicker(
                                "Last Completed",
                                selection: .init(
                                    get: { lastCompleted ?? Date() },
                                    set: { lastCompleted = $0 }
                                ),
                                displayedComponents: .date
                            )
                        }
                    }

                    Section("Notes") {
                        TextField("Additional notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(.white)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateTask()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func updateTask() {
        task.name = name
        task.taskDescription = description
        task.categoryID = selectedCategory?.id
        task.frequency = selectedFrequency
        task.estimatedDuration = estimatedDuration
        task.notes = notes
        task.lastCompleted = hasLastCompleted ? lastCompleted : nil
        task.updateNextDue()

        taskStore.updateTask(task)
        onComplete()
    }
}
