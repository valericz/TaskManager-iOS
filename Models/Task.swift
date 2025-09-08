//
//  Task.swift
//  TaskManager
//
//  Created by WEIHUA ZHANG on 8/9/2025.
//

import Foundation

// MARK: - Protocol: Task
/// A common interface that all task types must conform to.
/// Conforming types are reference types (`class`) because:
/// - They adopt `ObservableObject` for SwiftUI bindings.
/// - They are stored as `any Task` (existential) in arrays.
///
/// Required members:
/// - `id`: Stable identifier for list diffing.
/// - `title`, `description`: User-visible fields, editable.
/// - `isCompleted`: Completion state; implementations may customize `complete()`.
/// - `createdDate`: Immutable creation timestamp.
/// - `category`: High-level type used for filtering and icons.
/// - `getDisplayInfo()`: Short, user-readable summary for list rows.
/// - `getPriority()`: Derived priority (e.g., based on deadline or content).
protocol Task: ObservableObject, Identifiable {
    var id: UUID { get }
    var title: String { get set }
    var description: String { get set }
    var isCompleted: Bool { get set }
    var createdDate: Date { get }
    var category: TaskCategory { get }
    
    /// Mark the task as completed. Default behavior may be overridden.
    func complete()
    /// A short, human-friendly summary line for UI display.
    func getDisplayInfo() -> String
    /// Priority derived from task data. Used to color indicators, sort, etc.
    func getPriority() -> TaskPriority
}

// MARK: - Enums

/// High-level task categories for filtering and per-type UI.
enum TaskCategory: String, CaseIterable {
    case personal = "Personal"
    case work = "Work"
    case shopping = "Shopping"
    
    /// SF Symbol name used to render an icon for the category.
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .shopping: return "cart.fill"
        }
    }
}

/// Coarse priority levels used by the UI. Can be computed per task type.
enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    /// A simple textual color hint; UI maps this to actual SwiftUI `Color`.
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

// MARK: - BaseTask
/// A concrete base class providing common storage and default behaviors
/// for all task types. Subclasses add fields and override summaries/priority
/// logic as needed.
class BaseTask: Task {
    /// Stable UUID for `Identifiable`.
    let id = UUID()
    /// Title shown prominently in the list.
    @Published var title: String
    /// Short description shown under the title.
    @Published var description: String
    /// Completion status; toggled by `complete()` or the manager.
    @Published var isCompleted: Bool = false
    /// Creation timestamp; immutable once set.
    let createdDate: Date = Date()
    /// Category drives filtering and per-type UI (icon/fields).
    let category: TaskCategory
    
    init(title: String, description: String, category: TaskCategory) {
        self.title = title
        self.description = description
        self.category = category
    }
    
    /// Default completion simply flips the flag to `true`.
    /// Subclasses may extend this (e.g., mark child items purchased).
    func complete() {
        isCompleted = true
    }
    
    /// Default display string: "Title - Category".
    func getDisplayInfo() -> String {
        return "\(title) - \(category.rawValue)"
    }
    
    /// Default priority is medium; subclasses provide smarter logic.
    func getPriority() -> TaskPriority {
        return .medium
    }
}

// MARK: - Concrete Task Types (Inheritance / Composition)

/// Personal task with an optional free-form note.
class PersonalTask: BaseTask {
    @Published var personalNote: String
    
    init(title: String, description: String, personalNote: String = "") {
        self.personalNote = personalNote
        super.init(title: title, description: description, category: .personal)
    }
    
    override func getDisplayInfo() -> String {
        return "\(super.getDisplayInfo()) - Personal Note: \(personalNote)"
    }
    
    /// Heuristic: if user added a note, treat as at least medium priority.
    override func getPriority() -> TaskPriority {
        return personalNote.isEmpty ? .low : .medium
    }
}

/// Work task with an optional deadline and assignee.
class WorkTask: BaseTask {
    /// Optional due date; used to compute priority.
    @Published var deadline: Date?
    /// Person responsible (could be self or teammate).
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
    
    /// Priority based on how close the deadline is.
    /// - ≤ 1 day: .high
    /// - ≤ 7 days: .medium
    /// - else or no deadline: .low
    override func getPriority() -> TaskPriority {
