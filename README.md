# TaskManager - iOS Application

**Assessment Task 2: iOS Application Development with Object and Protocol-Oriented Concepts**  
**Course:** 40005 Advanced iOS Development - Spring 2025  
**Author:** Weihua Zhang  
**Date:** September 2024

## Project Overview

TaskManager is a comprehensive iOS application that demonstrates proficiency in object-oriented programming (OOP) and protocol-oriented programming (POP) concepts. The app allows users to efficiently manage different types of tasks with an intuitive SwiftUI interface, following the MVVM architectural pattern.

## Features

### Core Functionality
- ✅ **Create Tasks**: Add new tasks with category-specific properties
- ✅ **Read Tasks**: View tasks with filtering by category and completion status
- ✅ **Update Tasks**: Edit existing tasks while preserving their state
- ✅ **Delete Tasks**: Remove tasks with swipe gesture

### Task Types
- **Personal Tasks**: Include personal notes and low/medium priority
- **Work Tasks**: Feature deadlines, assignees, and dynamic priority calculation
- **Shopping Tasks**: Contain budget information and shopping item lists

### Advanced Features
- Real-time filtering by category (Personal, Work, Shopping)
- Toggle visibility of completed tasks
- Automatic priority calculation based on deadlines and urgency
- Responsive UI with immediate state updates
- Comprehensive error handling and user feedback

## Technical Architecture

### Object-Oriented Programming (OOP) Implementation

#### Inheritance Hierarchy
```
BaseTask (Abstract Base Class)
├── PersonalTask (Inherits common properties + personalNote)
├── WorkTask (Inherits common properties + deadline, assignee)
└── ShoppingTask (Inherits common properties + budget, items)
```

**Key OOP Concepts Demonstrated:**
- **Encapsulation**: Each task type encapsulates its specific properties and behaviors
- **Inheritance**: Common functionality in BaseTask, specialized behavior in subclasses
- **Polymorphism**: All task types conform to the same interface through the Task protocol

### Protocol-Oriented Programming (POP) Implementation

#### Core Protocol Design
```swift
protocol Task: ObservableObject, Identifiable {
    var id: UUID { get }
    var title: String { get set }
    var description: String { get set }
    var isCompleted: Bool { get set }
    var createdDate: Date { get }
    var category: TaskCategory { get }
    
    func complete()
    func getDisplayInfo() -> String
    func getPriority() -> TaskPriority
}
```

**POP Benefits Achieved:**
- **Code Modularity**: Protocol extensions provide default implementations
- **Type Safety**: Compile-time guarantees for consistent behavior
- **Testability**: Easy to mock and test through protocol conformance
- **Extensibility**: New task types can be added without modifying existing code

### MVVM Architecture Pattern

#### Components
- **Model**: Task protocol and concrete implementations (PersonalTask, WorkTask, ShoppingTask)
- **View**: SwiftUI components (ContentView, TaskListView, AddTaskView, EditTaskView)
- **ViewModel**: TaskManager class managing state and business logic

#### Reactive Programming
- Uses Combine framework for reactive state management
- @Published properties for automatic UI updates
- Publishers.CombineLatest for complex state coordination

## Project Structure

```
TaskManager/
├── Models/
│   └── Task.swift                  # Protocol definition and implementations
├── ViewModels/
│   └── TaskManager.swift           # MVVM ViewModel with business logic
├── Views/
│   └── ContentView.swift           # SwiftUI interface components
├── Data/
│   └── TaskDataStore.swift         # Data persistence layer
├── Utils/
│   └── TaskError.swift             # Error handling definitions
├── Tests/
│   └── TaskManagerTests.swift      # Unit tests
└── README.md                       # This documentation
```

## Error Handling

The application implements comprehensive error handling:

```swift
enum TaskError: LocalizedError {
    case emptyTitle
    case invalidData
    case taskNotFound
    case saveFailed
    case loadFailed
}
```

### Error Handling Features
- User-friendly error messages with recovery suggestions
- Graceful degradation when data loading fails
- Input validation with immediate feedback
- Proper error propagation through the application layers

## Testing

### Unit Testing Coverage
- ✅ Task creation and property validation
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Filtering and sorting logic
- ✅ Priority calculation algorithms
- ✅ Error handling scenarios

### Testing Framework
- Uses modern Swift Testing framework (@Test, #expect)
- Comprehensive test coverage for core functionality
- Performance testing for large data sets

## Installation and Setup

### Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

### Running the Application
1. Clone the repository
2. Open `TaskManager.xcodeproj` in Xcode
3. Select target device or simulator
4. Press ⌘+R to run the application

### Running Tests
- Press ⌘+U to run all unit tests
- Individual tests can be run from the Test Navigator

## Design Decisions and Implementation Highlights

### 1. Protocol-First Design
- Defined Task protocol before implementing concrete classes
- Ensured consistent behavior across all task types
- Enabled polymorphism and type safety

### 2. MVVM with Reactive Programming
- Separated business logic from UI concerns
- Used Combine for reactive state management
- Achieved automatic UI updates with minimal boilerplate

### 3. Composition Over Complex Inheritance
- ShoppingTask uses composition (contains ShoppingItem array)
- Avoided deep inheritance hierarchies
- Maintained flexibility and testability

### 4. SwiftUI Best Practices
- Modular view components for reusability
- Proper state management with @State and @EnvironmentObject
- Responsive UI with declarative syntax

## Key Learning Outcomes

### Object-Oriented Programming
- Effective use of inheritance for code reuse
- Proper encapsulation of data and behavior
- Polymorphism through protocol conformance

### Protocol-Oriented Programming
- Protocol-first design approach
- Protocol extensions for default implementations
- Enhanced modularity and testability

### iOS Development
- Modern SwiftUI development techniques
- MVVM architectural pattern implementation
- Reactive programming with Combine framework
- Comprehensive error handling strategies

## Future Enhancements

### Potential Improvements
- Cloud synchronization with iCloud
- Push notifications for task deadlines
- Advanced filtering and search capabilities
- Collaborative task sharing
- Rich text editing for task descriptions
- Attachment support for tasks

### Technical Debt
- View separation into individual files (currently consolidated)
- Enhanced data persistence with Core Data
- Improved accessibility support
- Comprehensive UI testing suite

## Git Repository

This project demonstrates proper version control practices:
- Clear, meaningful commit messages
- Incremental development with regular commits
- Proper branching strategy (main branch)
- Complete project history preservation

### Commit History Highlights
1. Initial project structure and models
2. Error handling implementation
3. Data persistence layer
4. MVVM ViewModel implementation
5. SwiftUI interface development
6. Unit testing framework
7. CRUD functionality completion
8. Bug fixes and final polish

**Assessment Compliance:**
- ✅ Object-Oriented Concepts Implementation
- ✅ Protocol-Oriented Design Application  
- ✅ Intuitive SwiftUI User Interface
- ✅ Comprehensive Error Handling
- ✅ Unit Testing and Debugging
- ✅ Git Version Control Usage
- ✅ Source Code Documentation
