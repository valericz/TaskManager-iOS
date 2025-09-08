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
        let taskData = tasks.compactMap { TaskData.from(task: $0) }
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

// MARK:DTO

struct TaskData: Codable {
    let id: UUID
    let title: String
    let description: String
    let isCompleted: Bool
    let createdDate: Date
    let categoryRawValue: String
    let taskType: TaskType
    let personalNote: String?
    let assignee: String?
    let deadline: Date?
    let budget: Double?
    let shoppingItems: [ShoppingItemData]?
    
    enum TaskType: String, Codable { case personal, work, shopping }
    
    var category: TaskCategory { TaskCategory(rawValue: categoryRawValue) ?? .personal }
    
    // MARK: encode from model
    static func from(task: any Task) -> TaskData? {
        if let p = task as? PersonalTask {
            return TaskData(
                id: p.id,
                title: p.title,
                description: p.description,
                isCompleted: p.isCompleted,
                createdDate: p.createdDate,
                categoryRawValue: p.category.rawValue,
                taskType: .personal,
                personalNote: p.personalNote,
                assignee: nil,
                deadline: nil,
                budget: nil,
                shoppingItems: nil
            )
        } else if let w = task as? WorkTask {
            return TaskData(
                id: w.id,
                title: w.title,
                description: w.description,
                isCompleted: w.isCompleted,
                createdDate: w.createdDate,
                categoryRawValue: w.category.rawValue,
                taskType: .work,
                personalNote: nil,
                assignee: w.assignee,
                deadline: w.deadline,
                budget: nil,
                shoppingItems: nil
            )
        } else if let s = task as? ShoppingTask {
            let items = s.items.map { ShoppingItemData.from(item: $0) }
            return TaskData(
                id: s.id,
                title: s.title,
                description: s.description,
                isCompleted: s.isCompleted,
                createdDate: s.createdDate,
                categoryRawValue: s.category.rawValue,
                taskType: .shopping,
                personalNote: nil,
                assignee: nil,
                deadline: nil,
                budget: s.budget,
                shoppingItems: items
            )
        }
        return nil
    }
    
    // MARK: decode to model
    func toTask() -> (any Task)? {
        switch taskType {
        case .personal:
            let t = PersonalTask(
                id: id,
                title: title,
                description: description,
                personalNote: personalNote ?? "",
                isCompleted: isCompleted,
                createdDate: createdDate
            )
            return t
        case .work:
            let t = WorkTask(
                id: id,
                title: title,
                description: description,
                deadline: deadline,
                assignee: assignee ?? "",
                isCompleted: isCompleted,
                createdDate: createdDate
            )
            return t
        case .shopping:
            let items = shoppingItems?.compactMap { $0.toShoppingItem() } ?? []
            let t = ShoppingTask(
                id: id,
                title: title,
                description: description,
                items: items,
                budget: budget ?? 0.0,
                isCompleted: isCompleted,
                createdDate: createdDate
            )
            return t
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
        ShoppingItemData(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            estimatedPrice: item.estimatedPrice,
            isPurchased: item.isPurchased,
            isUrgent: item.isUrgent
        )
    }
    
    func toShoppingItem() -> ShoppingItem {
        ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            estimatedPrice: estimatedPrice,
            isPurchased: isPurchased,
            isUrgent: isUrgent
        )
    }
}
