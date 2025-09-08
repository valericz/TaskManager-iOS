//
//  TaskManagerTests.swift
//  TaskManagerTests
//
//  Created on 2024/09/08.
//

import Testing

@Suite("Basic Tests")
struct TaskManagerTests {
    
    @Test("Basic functionality test")
    func basicTest() {
        let numbers = [1, 2, 3, 4, 5]
        let sum = numbers.reduce(0, +)
        #expect(sum == 15)
    }
    
    @Test("String test")
    func stringTest() {
        let text = "TaskManager"
        #expect(text.count == 11)
    }
    
    @Test("Array test")
    func arrayTest() {
        var items = ["Personal", "Work", "Shopping"]
        items.append("Home")
        #expect(items.count == 4)
    }
}
