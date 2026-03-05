import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var taskStore = TaskStore()
    @State private var selectedCategory: TaskCategory?
    @State private var selectedTab: SidebarItem = .dashboard
    @State private var showingAddTask = false
    @State private var searchText = ""

    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case allTasks = "All Tasks"
        case overdue = "Overdue"
        case upcoming = "Due Soon"
        case categories = "Categories"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "chart.pie.fill"
            case .allTasks: return "list.bullet"
            case .overdue: return "exclamationmark.triangle.fill"
            case .upcoming: return "calendar.badge.clock"
            case .categories: return "folder.fill"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return .purple
            case .allTasks: return .blue
            case .overdue: return .red
            case .upcoming: return .orange
            case .categories: return .green
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
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView { task in
                taskStore.addTask(task)
                showingAddTask = false
            }
        }
        .onAppear {
            taskStore.setContext(modelContext)
            SampleData.insertSampleData(context: modelContext)
        }
        .searchable(text: $searchText, placement: .toolbar)
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
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Button {
                        selectedTab = .categories
                        selectedCategory = category
                    } label: {
                        HStack {
                            Label(category.rawValue, systemImage: category.icon)
                                .foregroundStyle(categoryColor(category))
                            Spacer()
                        }
                    }
                    .buttonStyle(SidebarButtonStyle(isSelected: selectedTab == .categories && selectedCategory == category))
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func sidebarButton(for item: SidebarItem) -> some View {
        Button {
            selectedTab = item
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
        .buttonStyle(SidebarButtonStyle(isSelected: selectedTab == item))
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
                    title: category.rawValue,
                    taskStore: taskStore
                )
                .navigationTitle(category.rawValue)
            } else {
                CategoryGridView(taskStore: taskStore)
                    .navigationTitle("Categories")
            }
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

    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
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

struct CategoryGridView: View {
    let taskStore: TaskStore
    @State private var selectedCategory: TaskCategoryWrapper?

    let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = TaskCategoryWrapper(category: category)
                    } label: {
                        CategoryCard(category: category, taskStore: taskStore)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Categories")
        .sheet(item: $selectedCategory) { wrapper in
            NavigationStack {
                TaskListView(
                    tasks: taskStore.fetchTasksByCategory(wrapper.category),
                    title: wrapper.category.rawValue,
                    taskStore: taskStore
                )
            }
            .frame(minWidth: 800, minHeight: 600)
        }
    }
}

struct TaskCategoryWrapper: Identifiable {
    let id = UUID()
    let category: TaskCategory
}

struct CategoryCard: View {
    let category: TaskCategory
    let taskStore: TaskStore

    var taskCount: Int {
        taskStore.fetchTasksByCategory(category).count
    }

    var overdueCount: Int {
        taskStore.fetchTasksByCategory(category).filter { $0.isOverdue }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(categoryColor)

                Spacer()

                if overdueCount > 0 {
                    Text("\(overdueCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                }
            }

            Text(category.rawValue)
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
                        .fill(categoryColor.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: categoryColor.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private var categoryColor: Color {
        switch category {
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
