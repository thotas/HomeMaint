import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var taskStore = TaskStore()
    @State private var selectedCategory: Category?
    @State private var selectedTab: SidebarItem = .dashboard
    @State private var showingAddTask = false
    @State private var showingManageCategories = false
    @State private var searchText = ""
    @State private var showingExportPanel = false
    @State private var showingImportPanel = false
    @State private var exportManager = DataExportManager.shared
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var importResult: (imported: Int, skipped: Int) = (0, 0)
    @State private var errorManager = ErrorManager.shared

    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case allTasks = "All Tasks"
        case overdue = "Overdue"
        case upcoming = "Due Soon"
        case categories = "Categories"
        case manageCategories = "Manage Categories"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "chart.pie.fill"
            case .allTasks: return "list.bullet"
            case .overdue: return "exclamationmark.triangle.fill"
            case .upcoming: return "calendar.badge.clock"
            case .categories: return "folder.fill"
            case .manageCategories: return "gearshape.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return .purple
            case .allTasks: return .blue
            case .overdue: return .red
            case .upcoming: return .orange
            case .categories: return .green
            case .manageCategories: return .gray
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            NavigationStack {
                detailView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { showingAddTask = true }) {
                    Label("Add Task", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: exportTasks) {
                        Label("Export Tasks to CSV...", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { showingImportPanel = true }) {
                        Label("Import Tasks from CSV...", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Label("Data", systemImage: "externaldrive.connected.to.line.below")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskStore: taskStore) { task in
                taskStore.addTask(task)
                showingAddTask = false
            }
        }
        .sheet(isPresented: $showingManageCategories) {
            ManageCategoriesView(taskStore: taskStore)
        }
        .fileExporter(
            isPresented: $showingExportPanel,
            document: CSVDocument(),
            contentType: .commaSeparatedText,
            defaultFilename: "HomeMaint_Export"
        ) { result in
            switch result {
            case .success:
                showingExportSuccess = true
            case .failure(let error):
                print("Export error: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingImportPanel,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onAppear {
            taskStore.setContext(modelContext)
            SampleData.insertSampleData(context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .performUndo)) { _ in
            taskStore.performUndo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .performRedo)) { _ in
            taskStore.performRedo()
        }
        .searchable(text: $searchText, placement: .toolbar)
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Tasks have been exported to CSV.")
        }
        .alert("Import Complete", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Imported \(importResult.imported) tasks. \(importResult.skipped) tasks were skipped due to invalid data.")
        }
        .alert(errorManager.currentError?.errorDescription ?? "Error", isPresented: $errorManager.showingError) {
            Button("OK", role: .cancel) {
                errorManager.clearError()
            }
        } message: {
            Text(errorManager.currentError?.recoverySuggestion ?? "")
        }
    }

    private func exportTasks() {
        do {
            let tasks = taskStore.fetchAllTasks()
            let categories = taskStore.fetchAllCategories()
            let url = try exportManager.exportToCSV(tasks: tasks, categories: categories)

            // Copy to a file that can be selected
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.nameFieldStringValue = url.lastPathComponent

            if savePanel.runModal() == .OK, let destination = savePanel.url {
                try? FileManager.default.copyItem(at: url, to: destination)
                showingExportSuccess = true
            }
        } catch {
            print("Export error: \(error)")
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                let categories = taskStore.fetchAllCategories()
                var categoryLookup: [String: UUID] = [:]
                for category in categories {
                    categoryLookup[category.name.lowercased()] = category.id
                }

                let exportedTasks = try exportManager.importFromCSV(url: url, categories: categories)
                importResult = exportManager.importTasks(from: exportedTasks, categoryLookup: categoryLookup, taskStore: taskStore)
                showingImportSuccess = true
            } catch {
                print("Import error: \(error)")
            }
        case .failure(let error):
            print("Import error: \(error)")
        }
    }

    private var sidebar: some View {
        List {
            Section("Overview") {
                sidebarButton(for: .dashboard)
            }

            Section("Tasks") {
                sidebarButton(for: .allTasks)
                sidebarButton(for: .overdue)
                sidebarButton(for: .upcoming)
            }

            Section("Categories") {
                categoryButtons
            }

            Section("Settings") {
                sidebarButton(for: .manageCategories)
            }
        }
        .listStyle(.sidebar)
    }

    private var categoryButtons: some View {
        let categories = taskStore.fetchActiveCategories()
        return ForEach(categories) { category in
            Button {
                selectedTab = .categories
                selectedCategory = category
            } label: {
                HStack {
                    Label(category.name, systemImage: category.icon)
                        .foregroundStyle(category.color.swiftColor)
                    Spacer()
                }
            }
            .buttonStyle(SidebarButtonStyle(isSelected: selectedTab == .categories && selectedCategory?.id == category.id))
        }
    }

    private func sidebarButton(for item: SidebarItem) -> some View {
        Button {
            selectedTab = item
            if item == .manageCategories {
                showingManageCategories = true
                selectedTab = .dashboard // Reset to dashboard after triggering
            }
        } label: {
            HStack {
                Label(item.rawValue, systemImage: item.icon)
                    .foregroundStyle(item.color)
                Spacer()
                if item == .overdue {
                    let count = overdueCount
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .buttonStyle(SidebarButtonStyle(isSelected: selectedTab == item && item != .manageCategories))
    }

    struct SidebarButtonStyle: ButtonStyle {
        let isSelected: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.indigo.opacity(0.3) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.indigo.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(taskStore: taskStore)
                .navigationTitle("Dashboard")
        case .allTasks:
            TaskListView(
                tasks: filteredTasks(taskStore.fetchActiveTasks()),
                title: "All Tasks",
                taskStore: taskStore
            )
            .navigationTitle("All Tasks")
        case .overdue:
            TaskListView(
                tasks: filteredTasks(taskStore.fetchOverdueTasks()),
                title: "Overdue Tasks",
                taskStore: taskStore
            )
            .navigationTitle("Overdue Tasks")
        case .upcoming:
            TaskListView(
                tasks: filteredTasks(taskStore.fetchUpcomingTasks(days: 7)),
                title: "Due Soon",
                taskStore: taskStore
            )
            .navigationTitle("Due Soon")
        case .categories:
            if let category = selectedCategory {
                TaskListView(
                    tasks: taskStore.fetchTasksByCategory(category),
                    title: category.name,
                    taskStore: taskStore
                )
                .navigationTitle(category.name)
            } else {
                CategoryGridView(taskStore: taskStore)
                    .navigationTitle("Categories")
            }
        case .manageCategories:
            DashboardView(taskStore: taskStore)
                .navigationTitle("Dashboard")
        }
    }

    private var overdueCount: Int {
        taskStore.fetchOverdueTasks().count
    }

    private func filteredTasks(_ tasks: [MaintenanceTask]) -> [MaintenanceTask] {
        guard !searchText.isEmpty else { return tasks }
        return tasks.filter { task in
            task.name.localizedCaseInsensitiveContains(searchText) ||
            task.taskDescription.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct CategoryGridView: View {
    let taskStore: TaskStore
    @State private var selectedCategory: Category?

    let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(taskStore.fetchActiveCategories()) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        CategoryCard(category: category, taskStore: taskStore)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Categories")
        .sheet(item: $selectedCategory) { category in
            NavigationStack {
                TaskListView(
                    tasks: taskStore.fetchTasksByCategory(category),
                    title: category.name,
                    taskStore: taskStore
                )
            }
            .frame(minWidth: 800, minHeight: 600)
        }
    }
}

struct CategoryCard: View {
    let category: Category
    let taskStore: TaskStore

    var taskCount: Int {
        taskStore.getCategoryTaskCount(category)
    }

    var overdueCount: Int {
        taskStore.getCategoryOverdueCount(category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color.swiftColor)

                Spacer()

                if overdueCount > 0 {
                    Text("\(overdueCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                        .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }

            Text(category.name)
                .font(.headline)
                .foregroundStyle(.white)

            Text("\(taskCount) tasks")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding()
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.swiftColor.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(category.color.swiftColor.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: category.color.swiftColor.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}
