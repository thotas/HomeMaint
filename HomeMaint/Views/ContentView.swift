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
            detailView
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
        List(selection: $selectedTab) {
            Section("Overview") {
                ForEach([SidebarItem.dashboard]) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                            .foregroundStyle(item.color)
                    }
                }
            }

            Section("Tasks") {
                ForEach([SidebarItem.allTasks, .overdue, .upcoming]) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                            .foregroundStyle(item.color)
                    }
                    .badge(item == .overdue ? overdueCount : 0)
                }
            }

            Section("Categories") {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    NavigationLink(value: SidebarItem.categories) {
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundStyle(categoryColor(category))
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(taskStore: taskStore)
        case .allTasks:
            TaskListView(
                tasks: filteredTasks(taskStore.fetchActiveTasks()),
                title: "All Tasks",
                taskStore: taskStore
            )
        case .overdue:
            TaskListView(
                tasks: filteredTasks(taskStore.fetchOverdueTasks()),
                title: "Overdue Tasks",
                taskStore: taskStore
            )
        case .upcoming:
            TaskListView(
                tasks: filteredTasks(taskStore.fetchUpcomingTasks(days: 7)),
                title: "Due Soon",
                taskStore: taskStore
            )
        case .categories:
            CategoryGridView(taskStore: taskStore)
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
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }

            Text(category.rawValue)
                .font(.headline)
                .foregroundStyle(.primary)

            Text("\(taskCount) tasks")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
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
