# HomeMaint Architecture

## System Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              User Action                                │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              Views Layer                                │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │ ContentView  │ │ DashboardView│ │ TaskListView │ │TaskDetailView│   │
│  │(Navigation)  │ │(Stats + List)│ │(Sort/Filter) │ │ (Read/Edit)  │   │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │
│        │                  │                │               │            │
└────────┼──────────────────┼────────────────┼───────────────┼────────┘
         │                  │                │               │
         └──────────────────┴────────────────┴───────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           ViewModel Layer                               │
│                           ┌─────────────┐                               │
│                           │  TaskStore    │                               │
│                           │  (@Observable)│                               │
│                           ├─────────────┤                               │
│                           │• fetchAll()  │                               │
│                           │• fetchBy...() │                               │
│                           │• addTask()   │                               │
│                           │• updateTask() │                               │
│                           │• deleteTask() │                               │
│                           │• markComplete()│                              │
│                           │• getStats()   │                               │
│                           └─────────────┘                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                             Model Layer                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    MaintenanceTask (@Model)                       │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ id: UUID                     │ category: TaskCategory         │   │
│  │ name: String                  │ frequency: TaskFrequency         │   │
│  │ taskDescription: String       │ isActive: Bool                   │   │
│  │ lastCompleted: Date?         │ nextDue: Date (computed)        │   │
│  │ notes: String                 │ estimatedDuration: Int            │   │
│  │ createdAt: Date               │                                  │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ Methods: calculateNextDue(), markAsCompleted(), urgency          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Persistence Layer                              │
│                              SwiftData                                  │
│                    (Automatic SQLite storage)                            │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### Views

| View | Responsibility | States |
|------|----------------|--------|
| **ContentView** | Main navigation shell, sidebar selection | selectedTab, selectedCategory, showingAddTask |
| **DashboardView** | Statistics overview, priority tasks list | statistics (cached) |
| **TaskListView** | Sortable/filterable task list | sortOption, selectedTask |
| **TaskDetailView** | Full task information, edit actions | showingDeleteConfirmation, isEditing |
| **AddTaskView** | Create new task form | All form fields |
| **EditTaskView** | Modify existing task | All form fields |
| **CategoryGridView** | Category browser grid | selectedCategory |

### ViewModel

**TaskStore**
- Holds reference to ModelContext
- All CRUD operations go through here
- Observable for automatic UI updates
- Provides statistics aggregation

### Models

**MaintenanceTask**
- Core domain entity
- SwiftData @Model for persistence
- Computed properties for urgency, daysUntilDue
- Methods for business logic (markAsCompleted, calculateNextDue)

**TaskCategory (Enum)**
- 10 predefined categories
- Associated icon and color for UI

**TaskFrequency (Enum)**
- 7 frequency options
- Provides interval and dateComponent for calculations
- days property for progress calculations

**TaskUrgency (Enum)**
- 4 urgency levels
- Color and priority for sorting

## Data Flow

### 1. User Marks Task Complete

```
User taps "Mark Complete" button
        │
        ▼
TaskStore.markTaskComplete(task)
        │
        ▼
task.markAsCompleted() ──► lastCompleted = now
        │                       │
        │                       ▼
        │               task.updateNextDue()
        │                       │
        │                       ▼
        │               nextDue = calculateNextDue()
        │
        ▼
modelContext.save()
        │
        ▼
SwiftData persists to SQLite
        │
        ▼
@Observable triggers UI update
```

### 2. App Launch / Initial Load

```
HomeMaintApp init
        │
        ▼
Create ModelContainer (SwiftData)
        │
        ▼
ContentView appears
        │
        ▼
.onAppear: set context on TaskStore
        │
        ▼
SampleData.insertSampleData()
        │
        ▼
Fetch existing tasks ──► If empty, insert samples
        │
        ▼
Views observe TaskStore and render
```

### 3. Navigation Flow

```
User selects sidebar item
        │
        ▼
selectedTab changes
        │
        ▼
@ViewBuilder detailView switches
        │
        ▼
Appropriate view renders with data from TaskStore
        │
        ▼
User selects task from list
        │
        ▼
selectedTask = task
showingTaskDetail = true
        │
        ▼
Sheet presents TaskDetailView
```

## State Management

### Global State
- **ModelContext**: Injected at app level, passed to TaskStore
- **TaskStore**: Observable singleton pattern (per-view but shared context)

### View State
- **ContentView**: selectedTab (sidebar selection)
- **TaskListView**: sortOption, selectedTask
- **TaskDetailView**: showingDeleteConfirmation, isEditing
- **Form Views**: All form field state

### Persistent State
- **SwiftData**: All MaintenanceTask entities
- **UserDefaults**: App preferences (showCompleted, defaultView, reminderDays)

## Async/Concurrency Model

HomeMaint uses a **synchronous-first** approach:
- SwiftData operations are synchronous (local SQLite)
- No network calls, no async/await in core flow
- UI updates through @Observable are automatic

This keeps the architecture simple while remaining responsive.

## Error Handling

| Layer | Strategy |
|-------|----------|
| **SwiftData** | do-catch with print() for debugging |
| **Validation** | Disable save buttons when invalid |
| **User Feedback** | SwiftUI bindings show validation state |

## Extension Points

Future features can be added by:

1. **New Task Properties**: Add to MaintenanceTask model, SwiftData handles migration
2. **New Views**: Add to Views folder, wire into ContentView navigation
3. **New Categories**: Extend TaskCategory enum
4. **Export/Import**: Add methods to TaskStore for data serialization
5. **Sync**: Replace local ModelContainer with CloudKit-enabled container

## Performance Considerations

- **Lazy Loading**: Lists use LazyVStack/LazyVGrid for large datasets
- **Fetch Optimization**: Predicates filter at database level
- **State Minimization**: Only task IDs selected, not full objects
- **Image Caching**: SF Symbols are cached by system

## Testing Strategy

| Component | Approach |
|-----------|----------|
| **Models** | Unit tests for calculation logic |
| **ViewModels** | Unit tests with in-memory SwiftData |
| **Views** | Snapshot tests for UI regression |
| **Integration** | UI tests for user flows |
