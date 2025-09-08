//
//  TaskError.swift
//  TaskManager
//
//  Created by WEIHUA ZHANG on 8/9/2025.
//

import Foundation

enum TaskError: LocalizedError {
    case emptyTitle
    case invalidData
    case taskNotFound
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Task title cannot be empty"
        case .invalidData:
            return "Invalid task data provided"
        case .taskNotFound:
            return "Task not found"
        case .saveFailed:
            return "Failed to save task"
        case .loadFailed:
            return "Failed to load tasks"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyTitle:
            return "Please enter a valid title for your task"
        case .invalidData:
            return "Please check your input and try again"
        case .taskNotFound:
            return "The task may have been deleted or moved"
        case .saveFailed, .loadFailed:
            return "Please try again or restart the app"
        }
    }
}
