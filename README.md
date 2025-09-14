# Todo App - Offline-First Architecture

A comprehensive Flutter todo application built with Clean Architecture principles, implementing offline-first approach with multi-device synchronization capabilities.

## 🏗️ Architecture Overview

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                           # Core functionality
│   ├── database/                   # SQLite database setup
│   ├── error/                      # Error handling and failures
│   ├── network/                    # Network connectivity
│   └── sync/                       # Synchronization service
├── features/
│   └── todo/
│       ├── domain/                 # Business logic layer
│       │   ├── entities/           # Core business objects
│       │   ├── repositories/       # Repository interfaces
│       │   └── usecases/          # Business use cases
│       ├── data/                   # Data access layer
│       │   ├── models/             # Data models
│       │   ├── datasources/        # Local & Remote data sources
│       │   └── repositories/       # Repository implementations
│       └── presentation/           # UI layer
│           ├── bloc/               # State management
│           ├── pages/              # UI screens
│           └── widgets/            # UI components
└── injection_container.dart        # Dependency injection
```

## 🎯 Key Features

### 1. **Offline-First Architecture**
- All data is stored locally first (SQLite)
- App works completely offline
- Automatic background synchronization when online
- Conflict resolution using version numbers and timestamps

### 2. **Multi-Device/Multi-User Support**
- Real-time updates via WebSocket simulation
- Conflict resolution for simultaneous edits
- Version tracking for each todo item
- Mock data to simulate changes from other devices

### 3. **SOLID Principles Implementation**

#### Single Responsibility Principle (SRP)
- Each use case handles one specific business operation
- Separate data sources for local and remote operations
- Individual BLoC events for each user action

#### Open/Closed Principle (OCP)
- Repository pattern allows easy addition of new data sources
- Use case interfaces enable extension without modification
- Abstract classes for failures and data sources

#### Liskov Substitution Principle (LSP)
- Repository implementations are interchangeable
- Data source implementations follow contracts
- Failure types can be substituted without breaking code

#### Interface Segregation Principle (ISP)
- Focused interfaces for specific responsibilities
- Separate interfaces for local and remote data sources
- Use cases depend only on what they need

#### Dependency Inversion Principle (DIP)
- Domain layer depends on abstractions, not concretions
- Dependency injection for all external dependencies
- Repository interfaces in domain, implementations in data layer

### 4. **Design Patterns Used**

- **Repository Pattern**: Abstracts data access
- **Observer Pattern**: BLoC for state management
- **Factory Pattern**: Model creation and conversion
- **Strategy Pattern**: Conflict resolution strategies
- **Singleton Pattern**: Database and service instances

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.5.3)
- Dart SDK
- Android Studio / VS Code
- Physical device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd to_dp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🧪 Testing Multi-Device Functionality

Since we don't have a real backend, the app includes sophisticated mock systems to simulate multi-device scenarios:

### 1. **Mock WebSocket Updates**
- The app simulates receiving updates from other devices every 10 seconds
- Random todo updates appear to demonstrate real-time sync
- Look for todos with titles like "Updated by Device B" or "Modified on Phone"

### 2. **Testing Offline-First Behavior**

#### Test Scenario 1: Create todos offline
1. Turn off internet connection
2. Create several todos
3. Notice they save immediately (offline-first)
4. Turn internet back on
5. Watch sync status indicator change

#### Test Scenario 2: Conflict resolution
1. Create a todo
2. Wait for mock updates to simulate another device editing
3. Edit the same todo locally
4. Observe version numbers and conflict resolution

#### Test Scenario 3: Background sync
1. Create todos while online
2. Pull down to refresh
3. Notice sync status indicators
4. Background sync happens automatically every 5 minutes

### 3. **Visual Indicators**

- **Version Numbers**: Each todo shows version (v1, v2, etc.)
- **Sync Status Bar**: Shows "synchronized" or "working offline"
- **Sync Button**: Manual sync trigger in app bar
- **Pull to Refresh**: Triggers sync and refresh

### 4. **Simulating Multiple Devices**

To properly test multi-device scenarios:

1. **Option 1: Multiple Emulators**
   ```bash
   # Terminal 1
   flutter run -d emulator-5554
   
   # Terminal 2
   flutter run -d emulator-5556
   ```

2. **Option 2: Physical + Emulator**
   ```bash
   flutter run  # Physical device
   flutter run -d android
   ```

3. **Option 3: Web + Mobile**
   ```bash
   flutter run -d chrome
   flutter run -d android
   ```

## 🏗️ Architecture Deep Dive

### Data Flow

1. **User Action** → UI Widget
2. **Widget** → BLoC Event
3. **BLoC** → Use Case
4. **Use Case** → Repository Interface
5. **Repository** → Local Data Source (immediate)
6. **Repository** → Remote Data Source (background)
7. **Data Sources** → Database/API
8. **Response** ← Repository ← Use Cases ← BLoC
9. **UI Update** ← BLoC State Change

### Offline-First Implementation

```dart
// Always save locally first
final savedTodo = await localDataSource.insertTodo(todo);

// Then sync to remote in background
_backgroundSyncTodo(savedTodo);

// Return immediately with local data
return Right(savedTodo);
```

### Conflict Resolution Strategy

```dart
TodoModel resolveConflict(TodoModel localTodo, TodoModel remoteTodo) {
  // Last-write-wins based on version and timestamp
  if (remoteTodo.version > localTodo.version) {
    return remoteTodo; // Remote wins
  } else if (localTodo.version > remoteTodo.version) {
    return localTodo;  // Local wins
  } else {
    // Same version, use timestamp
    return remoteTodo.updatedAt.isAfter(localTodo.updatedAt) 
        ? remoteTodo 
        : localTodo;
  }
}
```

## 📱 User Interface Features

### Modern Material Design 3
- Clean, intuitive interface
- Consistent color scheme
- Proper loading states and error handling
- Responsive design

### Real-time Status Indicators
- Sync status bar (green = synced, orange = offline)
- Version badges on todo items
- Loading indicators during operations
- Error messages with retry options

### Smooth User Experience
- Immediate feedback for all actions
- Pull-to-refresh functionality
- Context menus and edit dialogs
- Form validation and user guidance
# offline_1st_architecture_to_do
