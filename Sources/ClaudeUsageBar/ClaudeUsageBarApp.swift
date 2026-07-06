import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @StateObject private var monitor = UsageMonitor()

    var body: some Scene {
        MenuBarExtra(monitor.state.menuBarText, systemImage: "bolt.fill") {
            UsageMenuView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
