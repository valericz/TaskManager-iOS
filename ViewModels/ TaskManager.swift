//
//   TaskManager.swift
//  TaskManager
//
//  Created by WEIHUA ZHANG on 8/9/2025.
//

import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [any Task] = []
    @Published var filteredTasks: [any Task] = []
    @Published var selectedCategory: TaskCategory?
    @Published var showCompletedTasks: Bool = true
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let dataStore = TaskDataStore()
    
    init() {
        setupFiltering()
        loadSampleTasks()
        applyFilters()
    }
    
    // MARK: - 任务管理方法
    
    func addTask(_ task: any Task) throws {
        guard !task.title.isEmpty else {
            throw TaskError.emptyTitle
        }
        
        tasks.append(task)
        saveTasks()
        applyFilters()
    }
    
    func deleteTask(withId id: UUID) throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw TaskError.taskNotFound
        }
        
        tasks.remove(at: index)
        saveTasks()
        applyFilters()
    }
    
    func updateTask(_ updatedTask: any Task) throws {
        guard let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) else {
            throw TaskError.taskNotFound
        }
        
        tasks[index] = updatedTask
        saveTasks()
        applyFilters()
    }
    
    func toggleTaskCompletion(withId id: UUID) throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw TaskError.taskNotFound
        }
        
        if tasks[index].isCompleted {
            tasks[index].isCompleted = false
        } else {
            tasks[index].complete()
        }
        
        saveTasks()
        applyFilters()
    }
    
    // MARK: - 数据持久化
    
    private func saveTasks() {
        do {
            try dataStore.saveTasks(tasks)
        } catch {
            handleError(TaskError.saveFailed)
        }
    }
    
    private func loadTasks() {
        do {
            tasks = try dataStore.loadTasks()
            applyFilters()
        } catch {
            // 如果加载失败，使用示例数据
            loadSampleTasks()
            handleError(TaskError.loadFailed)
        }
    }
    
    // MARK: - 筛选功能
    
    private func setupFiltering() {
        Publishers.CombineLatest3($tasks, $selectedCategory, $showCompletedTasks)
            .sink { [weak self] _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        print("=== applyFilters called ===")
        print("Total tasks: \(tasks.count)")
        print("Selected category: \(selectedCategory?.rawValue ?? "All")")
        print("Show completed: \(showCompletedTasks)")
        
        var filtered = tasks
        
        // 按类别筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
            print("After category filter: \(filtered.count)")
        }
        
        // 按完成状态筛选
        if !showCompletedTasks {
            filtered = filtered.filter { !$0.isCompleted }
            print("After completion filter: \(filtered.count)")
        }
        
        print("Final filtered count: \(filtered.count)")
        
        // 重要：确保在主线程更新UI
        DispatchQueue.main.async {
            self.filteredTasks = filtered
            print("UI updated with \(self.filteredTasks.count) tasks")
        }
    }
    
    func filterByCategory(_ category: TaskCategory?) {
        print("filterByCategory called with: \(category?.rawValue ?? "nil")")
        selectedCategory = category
        // 立即应用筛选，不等待 Combine 的异步更新
        applyFilters()
    }
    
    func refreshFilters() {
        applyFilters()
    }
    // MARK: - 错误处理
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    // MARK: - 示例数据
    
    private func loadSampleTasks() {
        let personalTask = PersonalTask(
            title: "Morning Exercise",
            description: "30 minutes jogging in the park",
            personalNote: "Remember to stretch before and after"
        )
        
        let workTask = WorkTask(
            title: "Complete Project Report",
            description: "Finish the quarterly analysis report",
            deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            assignee: "John Doe"
        )
        
        let shoppingTask = ShoppingTask(
            title: "Weekly Groceries",
            description: "Buy groceries for the week",
            items: [
                ShoppingItem(name: "Milk", quantity: 2, estimatedPrice: 5.0),
                ShoppingItem(name: "Bread", quantity: 1, estimatedPrice: 3.0, isUrgent: true),
                ShoppingItem(name: "Eggs", quantity: 12, estimatedPrice: 4.0)
            ],
            budget: 50.0
        )
        
        tasks = [personalTask, workTask, shoppingTask]
        applyFilters()
        
        print("Sample tasks loaded: \(tasks.count)")
        print("Filtered tasks: \(filteredTasks.count)")
    }
}
