# HomeMaint

A native macOS app for managing home maintenance tasks.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-14+-green)

## What It Does

HomeMaint helps you stay on top of your home maintenance responsibilities by tracking when tasks were last completed and when they're due next. Never forget to change your HVAC filter, clean your gutters, or check your smoke detectors again.

## Features

- **Dashboard Overview**: See at a glance how many tasks are overdue, due soon, or on track
- **Task Categories**: Organize tasks by category (HVAC, Plumbing, Electrical, Safety, Yard, etc.)
- **Smart Scheduling**: Tasks automatically calculate next due dates based on frequency
- **Visual Indicators**: Color-coded urgency indicators (red for overdue, orange for due soon, yellow for upcoming, green for on track)
- **Progress Tracking**: Visual progress bars show how close you are to the next due date
- **Sample Data**: Comes pre-loaded with 30+ common home maintenance tasks
- **Quick Actions**: Mark tasks complete with a single click
- **Full Edit Support**: Add, edit, and delete tasks as needed
- **Push Notifications**: Get notified before tasks are due
- **CSV Import/Export**: Export tasks to CSV and import from CSV files
- **Category Management**: Create, edit, and delete custom categories
- **Undo/Redo Support**: Undo and redo recent actions
- **Dark Mode**: Full dark mode support

## App Icon

HomeMaint features a professionally designed app icon inspired by Apple's design language:
- Modern gradient background (sky blue to indigo)
- Stylized house with roof and door
- Wrench badge indicating maintenance/handyman theme
- Full support for all macOS icon sizes (16px to 1024px)

The app icon is generated programmatically using Python and PIL. To regenerate the icon:

```bash
python3 generate_icon.py
```

## Screenshots

The app features a three-column layout:
- **Sidebar**: Navigate between Dashboard, All Tasks, Overdue, Due Soon, and Categories
- **Detail View**: Browse task lists or view the Dashboard with statistics
- **Modal Views**: Add/Edit tasks and view task details

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Swift 5.9 | Programming language |
| SwiftUI | UI framework |
| SwiftData | Data persistence (macOS 14+) |
| @Observable | Modern state management |

**Why SwiftData?**
- Native Apple framework designed for SwiftUI
- Automatic persistence with minimal boilerplate
- Type-safe model definitions with macros
- Excellent integration with SwiftUI views

**Why not Core Data?**
- SwiftData is the modern replacement for Core Data
- Less verbose model definitions
- Better SwiftUI integration
- Future-proof as Apple's recommended persistence solution

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for development)

## Installation

### From Source

```bash
git clone https://github.com/thotas/homemaint.git
cd homemaint
```

### Build

```bash
# Build from command line
./build.sh

# Or use Swift Package Manager
swift build
```

The built app will be at `HomeMaint.app`

To install to your Applications folder:

```bash
mv HomeMaint.app ~/Applications/
# Or to custom location
mv HomeMaint.app ~/Applications/myApps/
```

### Pre-built App

Download the latest release from the [Releases](https://github.com/thotas/homemaint/releases) page and drag `HomeMaint.app` to your Applications folder.

## How to Run

```bash
# Run the built app
open HomeMaint.app

# Or run from source using Swift Package Manager
swift run
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      HomeMaint                          │
├─────────────────────────────────────────────────────────┤
│  Views (SwiftUI)                                        │
│  ├── ContentView (NavigationSplitView)                  │
│  ├── DashboardView (Stats & Priority Tasks)             │
│  ├── TaskListView (Sortable task list)                  │
│  ├── TaskDetailView (Full task information)             │
│  └── AddTaskView / EditTaskView (CRUD forms)            │
├─────────────────────────────────────────────────────────┤
│  ViewModels                                             │
│  └── TaskStore (Observable data operations)             │
├─────────────────────────────────────────────────────────┤
│  Models                                                 │
│  ├── MaintenanceTask (@Model, SwiftData)                │
│  └── SampleData (Pre-populated tasks)                   │
├─────────────────────────────────────────────────────────┤
│  Persistence                                            │
│  └── SwiftData (Automatic local storage)                │
└─────────────────────────────────────────────────────────┘
```

## Folder Structure

```
HomeMaint/
├── HomeMaint/
│   ├── HomeMaintApp.swift          # App entry point
│   ├── Views/
│   │   ├── ContentView.swift       # Main navigation
│   │   ├── DashboardView.swift     # Statistics dashboard
│   │   ├── TaskListView.swift      # Task list with sorting
│   │   ├── TaskDetailView.swift    # Task detail modal
│   │   ├── AddTaskView.swift       # Add/Edit task forms
│   │   └── ManageCategoriesView.swift  # Category management
│   ├── ViewModels/
│   │   └── TaskStore.swift         # Data operations
│   ├── Models/
│   │   ├── MaintenanceTask.swift   # Core model
│   │   ├── Category.swift          # Task categories
│   │   ├── SampleData.swift        # Sample tasks
│   │   ├── UndoManager.swift       # Undo/Redo support
│   │   └── CSVDocument.swift       # CSV import/export
│   └── Services/
│       ├── NotificationManager.swift   # Push notifications
│       ├── DataExportManager.swift     # Data export
│       └── ErrorManager.swift          # Error handling
├── Package.swift                   # Swift Package Manager config
├── build.sh                        # Build script
├── generate_icon.py                # App icon generator
└── README.md                       # This file
```

## Key Concepts

### Task Urgency Levels

| Level | Color | Criteria |
|-------|-------|----------|
| Overdue | 🔴 Red | Due date has passed |
| Due Soon | 🟠 Orange | Due within 3 days |
| Upcoming | 🟡 Yellow | Due within 7 days |
| Normal | 🟢 Green | Due in more than 7 days |

### Task Frequency Options

- Weekly / Bi-weekly
- Monthly / Quarterly / Bi-annual
- Annual / Biennial (2 years)

### Categories

- **HVAC**: Heating, ventilation, air conditioning
- **Plumbing**: Water systems, drains, fixtures
- **Electrical**: Wiring, outlets, panels
- **Safety**: Smoke detectors, fire extinguishers, security
- **Exterior**: Roof, gutters, siding, paint
- **Interior**: Carpets, walls, fixtures
- **Appliances**: Major appliances maintenance
- **Yard & Garden**: Lawn care, trees, sprinklers
- **Cleaning**: Deep cleaning tasks

## Known Limitations

- No cloud sync (local storage only)
- No recurring task templates
- No photo attachments for tasks

## Roadmap

- [ ] iCloud sync across devices
- [ ] Task templates and custom frequencies
- [ ] Photo attachments for documentation
- [ ] iOS companion app
- [ ] PDF export

## License

MIT License - See LICENSE file for details

## Credits

Built with [Claude Code](https://claude.com/code) using the YOLO Build skill.
