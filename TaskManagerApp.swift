import SwiftUI

@main
struct TaskManagerApp: App {
    @StateObject private var taskManager = TaskManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(taskManager)
            }
        }
    }
}
