import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingAddTask = false

    var body: some View {
        VStack {
            FilterControlsView()
            TaskListView()
        }
        .navigationTitle("Task Manager")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView().environmentObject(taskManager)
        }
        .alert("Error", isPresented: $taskManager.showError) {
            Button("OK") { }
        } message: {
            Text(taskManager.errorMessage)
        }
    }
}

// MARK: - FilterControlsView

struct FilterControlsView: View {
    @EnvironmentObject var taskManager: TaskManager

    var body: some View {
        VStack {
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button("All") { taskManager.filterByCategory(nil) }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(taskManager.selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(taskManager.selectedCategory == nil ? .white : .primary)
                        .cornerRadius(15)

                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        Button {
                            taskManager.filterByCategory(category)
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(taskManager.selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(taskManager.selectedCategory == category ? .white : .primary)
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
            }

            // Completed toggle
            Toggle("Show Completed Tasks", isOn: $taskManager.showCompletedTasks)
                .padding(.horizontal)
                .onChange(of: taskManager.showCompletedTasks) { _, _ in
                    taskManager.refreshFilters()
                }
        }
    }
} // <<< IMPORTANT: close FilterControlsView here

// MARK: - TaskListView

struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager

    var body: some View {
        List {
            ForEach(taskManager.filteredTasks, id: \.id) { task in
                TaskRowView(task: task)
            }
            .onDelete(perform: deleteTask)
        }
        .listStyle(.plain)
    }

    private func deleteTask(offsets: IndexSet) {
        for index in offsets {
            let task = taskManager.filteredTasks[index]
            do {
                try taskManager.deleteTask(withId: task.id)
            } catch {
                taskManager.handleError(error)
            }
        }
    }
}

// MARK: - TaskRowView

struct TaskRowView: View {
    let task: any Task
    @EnvironmentObject var taskManager: TaskManager

    var body: some View {
        HStack {
            Button {
                do { try taskManager.toggleTaskCompletion(withId: task.id) }
                catch { taskManager.handleError(error) }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .opacity(task.isCompleted ? 0.6 : 1.0)

                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(task.getDisplayInfo())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack {
                Image(systemName: task.category.icon)
                Circle()
                    .fill(colorForPriority(task.getPriority()))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForPriority(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: .green
        case .medium: .yellow
        case .high: .red
        }
    }
}

// MARK: - AddTaskView

struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = TaskCategory.personal
    @State private var personalNote = ""
    @State private var assignee = ""
    @State private var deadline = Date()
    @State private var hasDeadline = false
    @State private var budget = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack { Image(systemName: category.icon); Text(category.rawValue) }
                                .tag(category)
                        }
                    }
                }

                switch selectedCategory {
                case .personal:
                    Section("Personal Details") {
                        TextField("Personal Note", text: $personalNote, axis: .vertical)
                    }
                case .work:
                    Section("Work Details") {
                        TextField("Assignee", text: $assignee)
                        Toggle("Has Deadline", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                        }
                    }
                case .shopping:
                    Section("Shopping Details") {
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
                    Button("Save") { saveTask() }.disabled(title.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: { Text(errorMessage) }
        }
    }

    private func saveTask() {
        do {
            let task: any Task
            switch selectedCategory {
            case .personal:
                task = PersonalTask(title: title, description: description, personalNote: personalNote)
            case .work:
                task = WorkTask(title: title, description: description,
                                deadline: hasDeadline ? deadline : nil, assignee: assignee)
            case .shopping:
                task = ShoppingTask(title: title, description: description, budget: Double(budget) ?? 0.0)
            }
            try taskManager.addTask(task)
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @StateObject private var taskManager = TaskManager()

    var body: some View {
        TabView {
            NavigationView {
                ContentView().environmentObject(taskManager)
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Tasks")
            }
        }
    }
}
