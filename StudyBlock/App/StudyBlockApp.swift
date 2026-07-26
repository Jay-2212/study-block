import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var terminationHandler: (() -> Void)?
    private var didTearDown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        performTeardown()
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        performTeardown()
    }

    private func performTeardown() {
        guard !didTearDown else { return }
        didTearDown = true
        terminationHandler?()
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
                .environment(appModel.listIcons)
                .frame(minWidth: 760, minHeight: 560)
                .onAppear {
                    appDelegate.terminationHandler = {
                        [capturedModel = appModel] in
                        capturedModel.shutdown()
                    }
                }
        }
        .defaultSize(width: 900, height: 660)
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text("Settings…")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra(
            "Study Block",
            systemImage: appModel.timer.isRunning ? "timer" : "timer.circle"
        ) {
            MenuBarContentView()
                .environment(appModel)
                .environment(appModel.listIcons)
        }

        Settings {
            SettingsView()
                .environment(appModel)
                .environment(appModel.listIcons)
                .frame(width: 720, height: 620)
        }
    }
}
