import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct StudyBlockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let appModel = AppModel()

    var body: some Scene {
        WindowGroup("Study Block", id: "main") {
            ContentView()
                .environment(appModel)
                .frame(minWidth: 760, minHeight: 560)
        }
        .defaultSize(width: 900, height: 660)

        MenuBarExtra(
            "Study Block",
            systemImage: appModel.timer.isRunning ? "timer" : "timer.circle"
        ) {
            MenuBarContentView()
                .environment(appModel)
        }

        Settings {
            SettingsView()
                .environment(appModel)
                .frame(width: 520, height: 360)
        }
    }
}
