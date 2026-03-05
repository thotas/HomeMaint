import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    let taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var deletingCategory: Category?

    private var categories: [Category] {
        taskStore.fetchAllCategories().sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                List {
                    ForEach(categories) { category in
                        CategoryRow(
                            category: category,
                            taskCount: taskStore.getCategoryTaskCount(category),
                            onEdit: { editingCategory = category },
                            onToggleActive: { taskStore.toggleCategoryActive(category) },
                            onDelete: { deletingCategory = category }
                        )
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.3))
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveCategory)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Manage Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(taskStore: taskStore, isPresented: $showingAddCategory)
            }
            .sheet(item: $editingCategory) { category in
                EditCategorySheet(
                    category: category,
                    taskStore: taskStore,
                    presentedCategory: $editingCategory
                )
            }
            .alert("Delete Category?", isPresented: Binding(
                get: { deletingCategory != nil },
                set: { if !$0 { deletingCategory = nil } }
            )) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let category = deletingCategory {
                        taskStore.deleteCategory(category)
                    }
                    deletingCategory = nil
                }
            } message: {
                if let category = deletingCategory {
                    let taskCount = taskStore.getCategoryTaskCount(category)
                    if taskCount > 0 {
                        Text("'\(category.name)' has \(taskCount) task(s). Existing tasks will be reassigned.")
                    } else {
                        Text("'\(category.name)' will be permanently deleted.")
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 620)
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
            taskStore.updateCategory(category)
        }
    }
}

private struct CategoryRow: View {
    let category: Category
    let taskCount: Int
    let onEdit: () -> Void
    let onToggleActive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.swiftColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(category.color.swiftColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.body.bold())
                    .foregroundStyle(.white)

                Text("\(taskCount) tasks")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if !category.isActive {
                Text("Inactive")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
            }

            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }

                Button(action: onToggleActive) {
                    Label(
                        category.isActive ? "Deactivate" : "Activate",
                        systemImage: category.isActive ? "pause.circle" : "play.circle"
                    )
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

private enum CategoryIconOptions {
    static let values = [
        "house.fill", "fan.fill", "drop.fill", "bolt.fill",
        "paintbrush.fill", "washer.fill", "checkmark.shield.fill",
        "leaf.fill", "sparkles", "tag.fill", "gearshape.fill",
        "flame.fill", "sun.max.fill", "thermometer", "wrench.fill",
        "hammer.fill", "screwdriver.fill", "lock.fill", "wifi",
        "tv.fill", "refrigerator", "stove", "sofa.fill",
        "bed.double.fill", "bath.fill", "tree.fill", "car.fill"
    ]
}

private struct CategoryEditorForm: View {
    @Binding var name: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: CategoryColor
    let validationMessage: String?

    var body: some View {
        Form {
            Section("Category Name") {
                TextField("Name", text: $name)
                    .font(.body)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Icon") {
                iconGrid
            }

            Section("Color") {
                colorGrid
            }

            Section {
                previewRow
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
    }

    private var iconGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
            ForEach(CategoryIconOptions.values, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(selectedIcon == icon ? .white : selectedColor.swiftColor)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIcon == icon ? selectedColor.swiftColor : Color.black.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var colorGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
            ForEach(CategoryColor.allCases, id: \.self) { color in
                Button {
                    selectedColor = color
                } label: {
                    Circle()
                        .fill(color.swiftColor)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var previewRow: some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor.swiftColor.opacity(0.2))
                    .frame(height: 60)

                HStack(spacing: 12) {
                    Image(systemName: selectedIcon)
                        .font(.title2)
                        .foregroundStyle(selectedColor.swiftColor)

                    Text(normalizedName.isEmpty ? "Category Name" : normalizedName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct AddCategorySheet: View {
    let taskStore: TaskStore
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor: CategoryColor = .indigo

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validationMessage: String? {
        if normalizedName.isEmpty {
            return "Category name is required."
        }

        if taskStore.isCategoryNameTaken(normalizedName) {
            return "A category with this name already exists."
        }

        return nil
    }

    private var canSave: Bool {
        validationMessage == nil
    }

    var body: some View {
        NavigationStack {
            CategoryEditorForm(
                name: $name,
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor,
                validationMessage: validationMessage
            )
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 560)
    }

    private func saveCategory() {
        guard canSave else { return }

        let category = Category(
            name: normalizedName,
            icon: selectedIcon,
            color: selectedColor,
            sortOrder: taskStore.fetchAllCategories().count
        )

        taskStore.addCategory(category)
        isPresented = false
    }
}

struct EditCategorySheet: View {
    let category: Category
    let taskStore: TaskStore
    @Binding var presentedCategory: Category?

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: CategoryColor

    init(category: Category, taskStore: TaskStore, presentedCategory: Binding<Category?>) {
        self.category = category
        self.taskStore = taskStore
        self._presentedCategory = presentedCategory
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon)
        _selectedColor = State(initialValue: category.color)
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validationMessage: String? {
        if normalizedName.isEmpty {
            return "Category name is required."
        }

        if taskStore.isCategoryNameTaken(normalizedName, excluding: category.id) {
            return "A category with this name already exists."
        }

        return nil
    }

    private var canSave: Bool {
        validationMessage == nil
    }

    var body: some View {
        NavigationStack {
            CategoryEditorForm(
                name: $name,
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor,
                validationMessage: validationMessage
            )
            .navigationTitle("Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentedCategory = nil
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateCategory()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 560)
    }

    private func updateCategory() {
        guard canSave else { return }

        category.name = normalizedName
        category.icon = selectedIcon
        category.color = selectedColor
        taskStore.updateCategory(category)
        presentedCategory = nil
    }
}
