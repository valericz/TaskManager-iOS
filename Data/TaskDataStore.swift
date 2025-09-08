//
//  TaskDataStore.swift
//  TaskManager
//
//  Created by WEIHUA ZHANG on 8/9/2025.
//


import Foundation

class TaskDataStore {
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "SavedTasks"
    
    func saveTasks(_ tasks: [any Task]) throws {
        let taskData = tasks.compactMap { task -> TaskData? in
            return TaskData.from(task: task)
        }
        
        guard let encoded = try? JSONEncoder().encode(taskData) else {
            throw TaskError.saveFailed
        }
        
        userDefaults.set(encoded, forKey: tasksKey)
    }
    
    func loadTasks() throws -> [any Task] {
        guard let data = userDefaults.data(forKey: tasksKey),
              let taskData = try? JSONDecoder().decode([TaskData].self, from: data) else {
            throw TaskError.loadFailed
        }
        
        return taskData.compactMap { $0.toTask() }
    }
}

// MARK: - 数据传输对象

struct TaskData: Codable {
    let id: UUID
    let title: String
    let description: String
    let isCompleted: Bool
    let createdDate: Date
    let categoryRawValue: String  // 改成存储 String
    let taskType: TaskType
    
    // 类型特定数据
    let personalNote: String?
    let assignee: String?
    let deadline: Date?
    let budget: Double?
    let shoppingItems: [ShoppingItemData]?
    
    enum TaskType: String, Codable {
        case personal, work, shopping
    }
    
    // 计算属性来访问 TaskCategory
    var category: TaskCategory {
        return TaskCategory(rawValue: categoryRawValue) ?? .personal
    }

    
    static func from(task: any Task) -> TaskData? {
        if let personalTask = task as? PersonalTask {
            return TaskData(
                id: task.id,
                title: task.title,
                description: task.description,
                isCompleted: task.isCompleted,
                createdDate: task.createdDate,
                categoryRawValue: task.category.rawValue,
                taskType: .personal,
                personalNote: personalTask.personalNote,
                assignee: nil,
                deadline: nil,
                budget: nil,
                shoppingItems: nil
            )
        } else if let workTask = task as? WorkTask {
            return TaskData(
                id: task.id,
                title: task.title,
                description: task.description,
                isCompleted: task.isCompleted,
                createdDate: task.createdDate,
                categoryRawValue: task.category.rawValue,
                taskType: .work,
                personalNote: nil,
                assignee: workTask.assignee,
                deadline: workTask.deadline,
                budget: nil,
                shoppingItems: nil
            )
        } else if let shoppingTask = task as? ShoppingTask {
            let itemsData = shoppingTask.items.map { ShoppingItemData.from(item: $0) }
            return TaskData(
                id: task.id,
                title: task.title,
                description: task.description,
                isCompleted: task.isCompleted,
                createdDate: task.createdDate,
                categoryRawValue: task.category.rawValue,
                taskType: .shopping,
                personalNote: nil,
                assignee: nil,
                deadline: nil,
                budget: shoppingTask.budget,
                shoppingItems: itemsData
            )
        }
        
        return nil
    }
    
    func toTask() -> (any Task)? {
        switch taskType {
        case .personal:
            let task = PersonalTask(
                title: title,
                description: description,
                personalNote: personalNote ?? ""
            )
            task.isCompleted = isCompleted
            return task
            
        case .work:
            let task = WorkTask(
                title: title,
                description: description,
                deadline: deadline,
                assignee: assignee ?? ""
            )
            task.isCompleted = isCompleted
            return task
            
        case .shopping:
            let items = shoppingItems?.compactMap { $0.toShoppingItem() } ?? []
            let task = ShoppingTask(
                title: title,
                description: description,
                items: items,
                budget: budget ?? 0.0
            )
            task.isCompleted = isCompleted
            return task
        }
    }
}

struct ShoppingItemData: Codable {
    let id: UUID
    let name: String
    let quantity: Int
    let estimatedPrice: Double
    let isPurchased: Bool
    let isUrgent: Bool
    
    static func from(item: ShoppingItem) -> ShoppingItemData {
        return ShoppingItemData(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            estimatedPrice: item.estimatedPrice,
            isPurchased: item.isPurchased,
            isUrgent: item.isUrgent
        )
    }
    
    func toShoppingItem() -> ShoppingItem {
        return ShoppingItem(
            name: name,
            quantity: quantity,
            estimatedPrice: estimatedPrice,
            isPurchased: isPurchased,
            isUrgent: isUrgent
        )
    }
}

