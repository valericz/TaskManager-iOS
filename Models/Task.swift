//
//  Task.swift
//  TaskManager
//
//  Created by WEIHUA ZHANG on 8/9/2025.
//


import Foundation

// MARK: - 协议定义
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

// MARK: - 枚举定义
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

enum TaskPriority: String, CaseIterable, Codable{
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

// MARK: - 基础任务类
class BaseTask: Task {
    let id = UUID()
    @Published var title: String
    @Published var description: String
    @Published var isCompleted: Bool = false
    let createdDate: Date = Date()
    let category: TaskCategory
    
    init(title: String, description: String, category: TaskCategory) {
        self.title = title
        self.description = description
        self.category = category
    }
    
    func complete() {
        isCompleted = true
    }
    
    func getDisplayInfo() -> String {
        return "\(title) - \(category.rawValue)"
    }
    
    func getPriority() -> TaskPriority {
        return .medium
    }
}

// MARK: - 具体任务类型实现（继承/组合）

// 个人任务
class PersonalTask: BaseTask {
    @Published var personalNote: String
    
    init(title: String, description: String, personalNote: String = "") {
        self.personalNote = personalNote
        super.init(title: title, description: description, category: .personal)
    }
    
    override func getDisplayInfo() -> String {
        return "\(super.getDisplayInfo()) - Personal Note: \(personalNote)"
    }
    
    override func getPriority() -> TaskPriority {
        return personalNote.isEmpty ? .low : .medium
    }
}

// 工作任务
class WorkTask: BaseTask {
    @Published var deadline: Date?
    @Published var assignee: String
    
    init(title: String, description: String, deadline: Date? = nil, assignee: String = "") {
        self.deadline = deadline
        self.assignee = assignee
        super.init(title: title, description: description, category: .work)
    }
    
    override func getDisplayInfo() -> String {
        let deadlineStr = deadline?.formatted(date: .abbreviated, time: .omitted) ?? "No deadline"
        return "\(super.getDisplayInfo()) - Deadline: \(deadlineStr), Assignee: \(assignee)"
    }
    
    override func getPriority() -> TaskPriority {
        guard let deadline = deadline else { return .low }
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if daysUntilDeadline <= 1 {
            return .high
        } else if daysUntilDeadline <= 7 {
            return .medium
        } else {
            return .low
        }
    }
}

// 购物任务
class ShoppingTask: BaseTask {
    @Published var items: [ShoppingItem]
    @Published var budget: Double
    
    init(title: String, description: String, items: [ShoppingItem] = [], budget: Double = 0.0) {
        self.items = items
        self.budget = budget
        super.init(title: title, description: description, category: .shopping)
    }
    
    override func complete() {
        super.complete()
        // 标记所有商品为已购买
        items.indices.forEach { items[$0].isPurchased = true }
    }
    
    override func getDisplayInfo() -> String {
        return "\(super.getDisplayInfo()) - Items: \(items.count), Budget: $\(String(format: "%.2f", budget)))"
    }
    
    override func getPriority() -> TaskPriority {
        let urgentItemsCount = items.filter { $0.isUrgent }.count
        return urgentItemsCount > 0 ? .high : .medium
    }
}

// 购物项目辅助结构

struct ShoppingItem: Identifiable {
    var id = UUID()
    var name: String
    var quantity: Int
    var estimatedPrice: Double
    var isPurchased: Bool = false
    var isUrgent: Bool = false
}
