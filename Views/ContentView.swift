//
//  ContentView.swift
//  TaskManager
//
//  SwiftUI Views implementing MVVM pattern for task management
//  Demonstrates protocol-oriented and object-oriented programming concepts
//

import SwiftUI

// MARK: - ContentView
/**
 * Main content view implementing MVVM pattern
 * - View layer in MVVM architecture
 * - Uses @EnvironmentObject for dependency injection of TaskManager (ViewModel)
 * - Demonstrates SwiftUI declarative UI principles
 */
struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager // ViewModel injection for MVVM pattern
    @State private var showingAddTask = false // Local view state management

    var body: some View {
        VStack {
            // Composition pattern: ContentView composed of smaller, reusable components
            FilterControlsView() // Encapsulated filtering functionality
            TaskListView()       // Encapsulated task display functionality
        }
        .navigationTitle("Task Manager")
        .toolbar {
            // Toolbar with add button for creating new tasks
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            // Modal presentation for task creation
            // Explicit environment object passing to maintain MVVM data flow
            AddTaskView().environmentObject(taskManager)
        }
        .alert("Error", isPresented: $taskManager.showError) {
            Button("OK") { }
        } message: {
            // Reactive error handling - UI automatically updates when ViewModel error state changes
            Text(taskManager.errorMessage)
        }
    }
}

// MARK: - FilterControlsView
/**
 * Filtering controls component demonstrating:
 * - Single Responsibility Principle (SRP) - only handles filtering UI
 * - Protocol-oriented design through TaskCategory enum conformance
 * - Reactive programming with Combine framework integration
 */
struct FilterControlsView: View {
    @EnvironmentObject var taskManager: TaskManager // Shared ViewModel reference

    var body: some View {
        VStack {
            // Category filtering using protocol-oriented design
            // TaskCategory.allCases leverages CaseIterable protocol
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // "All" button for clearing category filter (nil state)
                    Button("All") { taskManager.filterByCategory(nil) }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        // Conditional styling based on selection state
                        .background(taskManager.selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(taskManager.selectedCategory == nil ? .white : .primary)
                        .cornerRadius(15)

                    // Dynamic button generation using protocol-oriented approach
                    // ForEach works with TaskCategory because it conforms to CaseIterable & Hashable
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Button {
                            // Polymorphic behavior - each category handles filtering differently
                            taskManager.filterByCategory(category)
                        } label: {
                            HStack {
                                // Protocol-defined icon property access
                                Image(systemName: category.icon)
                                Text(category.rawValue) // Enum raw value access
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        // State-dependent styling using protocol comparison
                        .background(taskManager.selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(taskManager.selectedCategory == category ? .white : .primary)
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
            }

            // Completion status toggle with reactive updates
            // Demonstrates two-way data binding in MVVM pattern
            Toggle("Show Completed Tasks", isOn: $taskManager.showCompletedTasks)
                .padding(.horizontal)
                .onChange(of: taskManager.showCompletedTasks) { _, _ in
                    // Manual filter refresh to ensure immediate UI updates
                    // Addresses potential async timing issues in reactive programming
                    taskManager.refreshFilters()
                }
        }
    }
} // FilterControlsView boundary - important for proper struct scoping

// MARK: - TaskListView
/**
 * Task list display component implementing:
 * - Protocol-oriented design - works with any Task protocol conforming objects
 * - Polymorphism - displays different task types uniformly
 * - Error handling integration with ViewModel
 */
struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager // Shared state management

    var body: some View {
        List {
            // Protocol-oriented iteration - works with heterogeneous task collection
            // Each task conforms to Task protocol, enabling polymorphic behavior
            ForEach(taskManager.filteredTasks, id: \.id) { task in
                // Composition: TaskRowView handles individual task display
                // Protocol conformance ensures all tasks have required properties (id, title, etc.)
                TaskRowView(task: task)
            }
            .onDelete(perform: deleteTask) // Swipe-to-delete gesture handling
        }
        .listStyle(.plain) // Modern SwiftUI styling approach
    }

    /**
     * Delete task handler demonstrating error handling patterns
     * - Uses do-catch for proper error propagation
     * - Integrates with ViewModel's error handling system
     */
    private func deleteTask(offsets: IndexSet) {
        for index in offsets {
            // Protocol-guaranteed id property access
            let task = taskManager.filteredTasks[index]
            do {
                // ViewModel method call with error handling
                try taskManager.deleteTask(withId: task.id)
            } catch {
                // Centralized error handling through ViewModel
                taskManager.handleError(error)
            }
        }
    }
}

// MARK: - TaskRowView
/**
 * Individual task row component showcasing:
 * - Protocol-oriented design - accepts any Task protocol conforming object
 * - Polymorphic behavior - displays different task types with common interface
 * - Encapsulation - self-contained task display logic
 */
struct TaskRowView: View {
    let task: any Task // Protocol type - enables polymorphism across task types
    @EnvironmentObject var taskManager: TaskManager // ViewModel reference for actions
    @State private var showingEditTask = false // Local view state for edit modal
    
    var body: some View {
        HStack {
            // Task completion toggle button
            // Demonstrates protocol-guaranteed property access (isCompleted)
            Button(action: {
                do {
                    // Protocol-guaranteed id property for task identification
                    try taskManager.toggleTaskCompletion(withId: task.id)
                } catch {
                    // Consistent error handling pattern
                    taskManager.handleError(error)
                }
            }) {
                // Visual state representation based on protocol property
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Protocol-guaranteed properties access - title, description
                // All Task protocol conforming objects must implement these
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted) // Visual completion indicator
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Polymorphic method call - each task type implements getDisplayInfo() differently
                // This demonstrates protocol-oriented programming benefits
                Text(task.getDisplayInfo())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                // Protocol-guaranteed category property with enum-defined icon
                Image(systemName: task.category.icon)
                    .foregroundColor(.blue)
                
                // Polymorphic priority calculation - each task type has different logic
                // Protocol ensures all tasks can calculate priority, implementation varies
                Circle()
                    .fill(colorForPriority(task.getPriority()))
                    .frame(width: 12, height: 12)
            }
            
            // Edit functionality button
            Button(action: {
                showingEditTask = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle()) // Prevents list row selection interference
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditTask) {
            // Modal presentation for task editing
            // Protocol type passed to EditTaskView enables polymorphic editing
            EditTaskView(task: task, taskManager: taskManager)
        }
    }
    
    /**
     * Priority-based color mapping function
     * Demonstrates enum pattern matching and consistent visual design
     */
    private func colorForPriority(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - AddTaskView
/**
 * Task creation view demonstrating:
 * - Object-oriented design - creates different task types based on selection
 * - Factory pattern - constructs appropriate task objects
 * - Form validation and error handling
 */
struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager // ViewModel for data operations
    @Environment(\.presentationMode) var presentationMode // SwiftUI navigation control

    // Form state management - separate concerns for each task type
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = TaskCategory.personal // Default selection
    
    // Task-type specific properties - demonstrates composition over inheritance
    @State private var personalNote = ""        // PersonalTask specific
    @State private var assignee = ""            // WorkTask specific
    @State private var deadline = Date()        // WorkTask specific
    @State private var hasDeadline = false      // WorkTask specific
    @State private var budget = ""              // ShoppingTask specific
    
    // Error handling state
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Common properties section - applies to all task types
                Section("Basic Information") {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    // Category picker using protocol-oriented design
                    // TaskCategory enum provides cases and display properties
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)  // Protocol-defined property
                                Text(category.rawValue)           // Enum raw value
                            }
                            .tag(category)
                        }
                    }
                }

                // Dynamic form sections based on selected category
                // Demonstrates object-oriented principle of showing only relevant data
                switch selectedCategory {
                case .personal:
                    Section("Personal Details") {
                        // PersonalTask specific fields
                        TextField("Personal Note", text: $personalNote, axis: .vertical)
                    }
                case .work:
                    Section("Work Details") {
                        // WorkTask specific fields
                        TextField("Assignee", text: $assignee)
                        Toggle("Has Deadline", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                        }
                    }
                case .shopping:
                    Section("Shopping Details") {
                        // ShoppingTask specific fields
                        TextField("Budget", text: $budget).keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Form validation - disabled when required fields empty
                    Button("Save") { saveTask() }.disabled(title.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    /**
     * Task creation factory method demonstrating:
     * - Object-oriented instantiation of different task types
     * - Polymorphism - different constructors for different types
     * - Error handling with proper propagation to ViewModel
     */
    private func saveTask() {
        do {
            // Factory pattern - create appropriate task type based on selection
            let task: any Task
            switch selectedCategory {
            case .personal:
                // PersonalTask instantiation with specific properties
                task = PersonalTask(title: title, description: description, personalNote: personalNote)
            case .work:
                // WorkTask instantiation with conditional deadline
                task = WorkTask(title: title, description: description,
                                deadline: hasDeadline ? deadline : nil, assignee: assignee)
            case .shopping:
                // ShoppingTask instantiation with budget conversion
                task = ShoppingTask(title: title, description: description, budget: Double(budget) ?? 0.0)
            }
            
            // ViewModel integration - delegate data operations to business logic layer
            try taskManager.addTask(task)
            presentationMode.wrappedValue.dismiss()
        } catch {
            // Error handling - convert system errors to user-friendly messages
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - EditTaskView
/**
 * Task editing view demonstrating:
 * - Protocol-oriented design - works with any Task conforming object
 * - Object mutation while preserving object identity
 * - Type-safe casting for accessing subclass-specific properties
 */
struct EditTaskView: View {
    let originalTask: any Task // Protocol type for polymorphic editing
    @EnvironmentObject var taskManager: TaskManager // ViewModel reference
    @Environment(\.presentationMode) var presentationMode // Navigation control
    
    // Form state - initialized from existing task properties
    @State private var title: String
    @State private var description: String
    @State private var personalNote: String = ""
    @State private var assignee: String = ""
    @State private var deadline: Date = Date()
    @State private var hasDeadline: Bool = false
    @State private var budget: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    /**
     * Custom initializer demonstrating:
     * - Protocol property access for common fields
     * - Type casting for accessing subclass-specific properties
     * - Safe optional handling for different task types
     */
    init(task: any Task, taskManager: TaskManager) {
        self.originalTask = task
        
        // Initialize common properties from protocol
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        
        // Type-specific property initialization using safe casting
        // Demonstrates runtime type checking and safe property access
        if let personalTask = task as? PersonalTask {
            _personalNote = State(initialValue: personalTask.personalNote)
        } else if let workTask = task as? WorkTask {
            _assignee = State(initialValue: workTask.assignee)
            _hasDeadline = State(initialValue: workTask.deadline != nil)
            if let deadline = workTask.deadline {
                _deadline = State(initialValue: deadline)
            }
        } else if let shoppingTask = task as? ShoppingTask {
            _budget = State(initialValue: String(shoppingTask.budget))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Common properties section - protocol-guaranteed fields
                Section("Basic Information") {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Type-specific sections based on original task category
                // Category cannot be changed during editing to maintain object integrity
                if originalTask.category == .personal {
                    Section("Personal Details") {
                        TextField("Personal Note", text: $personalNote, axis: .vertical)
                    }
                } else if originalTask.category == .work {
                    Section("Work Details") {
                        TextField("Assignee", text: $assignee)
                        Toggle("Has Deadline", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                        }
                    }
                } else if originalTask.category == .shopping {
                    Section("Shopping Details") {
                        TextField("Budget", text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty) // Form validation
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    /**
     * Save changes method demonstrating:
     * - Direct object mutation to preserve object identity
     * - Type casting for accessing mutable subclass properties
     * - Reactive UI updates through ViewModel
     */
    private func saveChanges() {
        // Direct property mutation maintains object identity and relationships
        // Type casting enables access to subclass-specific mutable properties
        if let personalTask = originalTask as? PersonalTask {
            personalTask.title = title
            personalTask.description = description
            personalTask.personalNote = personalNote
        } else if let workTask = originalTask as? WorkTask {
            workTask.title = title
            workTask.description = description
            workTask.assignee = assignee
            workTask.deadline = hasDeadline ? deadline : nil
        } else if let shoppingTask = originalTask as? ShoppingTask {
            shoppingTask.title = title
            shoppingTask.description = description
            shoppingTask.budget = Double(budget) ?? 0.0
        }
        
        // Trigger reactive UI updates through ViewModel
        // No need for complex state management - direct mutation with reactive refresh
        taskManager.refreshFilters()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - MainTabView
/**
 * Root application view implementing:
 * - Dependency injection pattern for MVVM architecture
 * - Single source of truth for application state
 * - Proper SwiftUI data flow patterns
 */
struct MainTabView: View {
    // ViewModel instantiation - single source of truth for application state
    @StateObject private var taskManager = TaskManager()

    var body: some View {
        TabView {
            NavigationView {
                // Dependency injection - provide ViewModel to entire view hierarchy
                // Enables MVVM pattern throughout the application
                ContentView().environmentObject(taskManager)
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Tasks")
            }
        }
    }
}
