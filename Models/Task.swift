//
//  Task.swift
//  TaskManager
//
//  Created by WEIHUA ZHANG on 8/9/2025.
//

import Foundation
import Combine

// MARK: - Protocol: Task
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

// MARK: - Enums
enum TaskCategory: String, CaseIterable {
    case personal = "Personal"
    case work = "Work"
    case shopping = "Shopping"
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .shopping: return "cart.fill"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

// MARK: - BaseTask
class BaseTask: Task {
    let id: UUID
    @Published var title: String
    @Published var description: String
    @Published var isCompleted: Bool
    let createdDate: Date
    let category: TaskCategory
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TaskCategory,
        isCompleted: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.isCompleted = isCompleted
        self.createdDate = createdDate
    }
    
    func complete() { isCompleted = true }
    
    func getDisplayInfo() -> String {
        "\(title) - \(category.rawValue)"
    }
    
    func getPriority() -> TaskPriority { .medium }
}

// MARK: - Concrete Task Types

// Personal
class PersonalTask: BaseTask {
    @Published var personalNote: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        personalNote: String = "",
        isCompleted: Bool = false,
        createdDate: Date = Date()
    ) {
        self.personalNote = personalNote
        super.init(
            id: id,
            title: title,
            description: description,
            category: .personal,
            isCompleted: isCompleted,
            createdDate: createdDate
        )
    }
    
    override func getDisplayInfo() -> String {
        "\(super.getDisplayInfo()) - Personal Note: \(personalNote)"
    }
    
    override func getPriority() -> TaskPriority {
        personalNote.isEmpty ? .low : .medium
    }
}

// Work
class WorkTask: BaseTask {
    @Published var deadline: Date?
    @Published var assignee: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        deadline: Date? = nil,
        assignee: String = "",
        isCompleted: Bool = false,
        createdDate: Date = Date()
    ) {
        self.deadline = deadline
        self.assignee = assignee
        super.init(
            id: id,
            title: title,
            description: description,
            category: .work,
            isCompleted: isCompleted,
            createdDate: createdDate
        )
    }
    
    override func getDisplayInfo() -> String {
        let deadlineStr = deadline?.formatted(date: .abbreviated, time: .omitted) ?? "No deadline"
        return "\(super.getDisplayInfo()) - Deadline: \(deadlineStr), Assignee: \(assignee)"
    }
    
    override func getPriority() -> TaskPriority {
        guard let deadline = deadline else { return .low }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? .max
        if days <= 1 { return .high }
        if days <= 7 { return .medium }
        return .low
    }
}

// MARK: - Shopping domain types

/// 单个购物条目
struct ShoppingItem: Identifiable {
    let id: UUID
    var name: String
    var quantity: Int
    var estimatedPrice: Double
    var isPurchased: Bool
    var isUrgent: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        estimatedPrice: Double,
        isPurchased: Bool = false,
        isUrgent: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.estimatedPrice = estimatedPrice
        self.isPurchased = isPurchased
        self.isUrgent = isUrgent
    }
}

/// 购物任务
class ShoppingTask: BaseTask {
    @Published var items: [ShoppingItem]
    @Published var budget: Double
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        items: [ShoppingItem] = [],
        budget: Double = 0.0,
        isCompleted: Bool = false,
        createdDate: Date = Date()
    ) {
        self.items = items
        self.budget = budget
        super.init(
            id: id,
            title: title,
            description: description,
            category: .shopping,
            isCompleted: isCompleted,
            createdDate: createdDate
        )
    }
    
    override func getDisplayInfo() -> String {
        let bought = items.filter { $0.isPurchased }.count
        return "\(super.getDisplayInfo()) - Items: \(items.count) (\(bought) bought), Budget: \(budget)"
    }
    
    override func getPriority() -> TaskPriority {
        if items.contains(where: { $0.isUrgent && !$0.isPurchased }) { return .high }
        return items.isEmpty ? .low : .medium
    }
    
    override func complete() {
        items = items.map { i in
            var c = i; c.isPurchased = true; return c
        }
        super.complete()
    }
}
