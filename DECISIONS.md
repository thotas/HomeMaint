# HomeMaint Design Decisions

## Platform & Tech Stack

### Chosen: Native macOS app with SwiftUI + SwiftData

**Alternatives considered:**
- Electron/Tauri with web technologies
- React Native for cross-platform
- AppKit for legacy compatibility

**Rationale:**
- Native macOS apps provide the best user experience on Apple platforms
- SwiftUI offers modern declarative UI with less code than AppKit
- SwiftData is Apple's recommended persistence framework for new apps
- Native performance and battery efficiency

**Tradeoffs:**
- macOS-only (no Windows/Linux support)
- Requires macOS 14+ for SwiftData features

---

## UI Framework

### Chosen: SwiftUI with NavigationSplitView

**Alternatives considered:**
- AppKit with storyboards
- AppKit with programmatic UI
- Catalyst for iPad-like interface

**Rationale:**
- Modern declarative syntax reduces boilerplate
- Built-in support for macOS features (sidebar, toolbars, sheets)
- NavigationSplitView provides standard three-pane layout
- Automatic dark mode support

**Tradeoffs:**
- Some customization limitations compared to AppKit
- Newer framework with occasional API changes

---

## Data Persistence

### Chosen: SwiftData with @Model macro

**Alternatives considered:**
- Core Data (tried and true)
- UserDefaults (too simple)
- SQLite directly (too much boilerplate)
- CloudKit (requires iCloud setup)

**Rationale:**
- SwiftData is purpose-built for SwiftUI
- Automatic model versioning
- Type-safe queries with #Predicate
- Minimal boilerplate compared to Core Data
- Built on Core Data so it's production-ready

**Tradeoffs:**
- Requires macOS 14.0+
- Less community documentation than Core Data
- Some advanced Core Data features not exposed

---

## State Management

### Chosen: @Observable macro with custom TaskStore

**Alternatives considered:**
- @StateObject / @ObservedObject with ObservableObject
- Redux-style state management
- MVVM with Combine

**Rationale:**
- @Observable (introduced in iOS 17/macOS 14) is more efficient
- Simpler syntax - no need for objectWillChange
- TaskStore acts as a clean abstraction layer
- Fine-grained reactivity without extra wrappers

**Tradeoffs:**
- Requires macOS 14+
- Still relatively new pattern

---

## Default Sort Order

### Chosen: Tasks sorted by due date (soonest first)

**Alternatives considered:**
- Alphabetical by name
- Category grouping
- Last completed date
- Manual ordering

**Rationale:**
- Users care most about what needs attention soon
- Overdue tasks appear at top naturally
- Reduces cognitive load - no need to scan entire list

**Tradeoffs:**
- Tasks with same due date may appear in arbitrary order
- Requires sort option for other views (provided in toolbar)

---

## Default Theme

### Chosen: Dark mode first with automatic system adaptation

**Alternatives considered:**
- Light mode default
- Force dark mode only
- User-selectable theme

**Rationale:**
- macOS users overwhelmingly prefer dark mode
- SwiftUI makes supporting both trivial
- Professional tools look better in dark mode

**Tradeoffs:**
- Testing required in both modes
- Some colors need adjustment per mode

---

## Sample Data Strategy

### Chosen: 30+ pre-populated tasks with realistic due dates

**Alternatives considered:**
- Empty database on first launch
- Tutorial/demo mode
- Import from external source

**Rationale:**
- Users understand the app immediately
- Realistic sample data shows value proposition
- Mixed due dates (some overdue, some coming up) show urgency system

**Tradeoffs:**
- Increases app size slightly
- May need to be cleared for power users

---

## Modal vs Inline Editing

### Chosen: Sheets for Add/Edit/Detail views

**Alternatives considered:**
- Inline editing in list
- Navigation to detail pages
- Inspector panel (right sidebar)

**Rationale:**
- Sheets are standard macOS pattern for modal tasks
- Keeps context visible behind the modal
- Better focus on the specific task
- Easier to dismiss/cancel

**Tradeoffs:**
- More clicks to navigate between tasks
- Sheets can feel heavy for quick edits

---

## Task Frequency Model

### Chosen: Enum with interval and dateComponent

**Alternatives considered:**
- Free-form text entry
- Number of days only
- Cron-like expressions

**Rationale:**
- Enums provide type safety
- Predefined options cover 95% of use cases
- Simpler UI (picker vs text input)
- Easier to calculate next due dates

**Tradeoffs:**
- Custom frequencies not supported
- Power users may want more flexibility
