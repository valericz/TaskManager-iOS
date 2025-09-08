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
    @State private var showingEditTask = false
    
    var body: some View {
        HStack {
            // 完成状态按钮
            Button(action: {
                do {
                    try taskManager.toggleTaskCompletion(withId: task.id)
                } catch {
                    taskManager.handleError(error)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 任务标题
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                
                // 任务描述
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 任务详细信息
                Text(task.getDisplayInfo())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                // 类别图标
                Image(systemName: task.category.icon)
                    .foregroundColor(.blue)
                
                // 优先级指示器
                Circle()
                    .fill(colorForPriority(task.getPriority()))
                    .frame(width: 12, height: 12)
            }
            
            // 添加编辑按钮
            Button(action: {
                showingEditTask = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task, taskManager: taskManager)
        }
    }
    
    private func colorForPriority(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
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
//
//  EditTaskView.swift
//  TaskManager
//
//

struct EditTaskView: View {
    let originalTask: any Task
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var personalNote: String = ""
    @State private var assignee: String = ""
    @State private var deadline: Date = Date()
    @State private var hasDeadline: Bool = false
    @State private var budget: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(task: any Task, taskManager: TaskManager) {
        self.originalTask = task
        
        // 初始化状态
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        
        // 根据任务类型初始化特定字段
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
                Section("Basic Information") {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // 根据任务类型显示相应的编辑字段
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
                    .disabled(title.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveChanges() {
        // 直接修改原始任务的属性
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
        
        // 只需要触发UI更新
        taskManager.refreshFilters()
        presentationMode.wrappedValue.dismiss()
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
