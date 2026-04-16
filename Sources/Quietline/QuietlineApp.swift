import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct QuietlineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = ProjectViewModel()

    var body: some Scene {
        WindowGroup("Quietline") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1100, minHeight: 720)
        }
        .windowResizability(.contentSize)
    }
}
