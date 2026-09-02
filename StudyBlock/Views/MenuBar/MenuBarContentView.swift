import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if appModel.timer.isRunning {
            Label(appModel.timer.formattedTime, systemImage: "timer")
                .monospacedDigit()
            Divider()
            Button(
                appModel.timer.isPanelVisible ? "Hide Floating Timer" : "Show Floating Timer"
            ) {
                appModel.timer.togglePanelVisibility()
            }
            Button("Stop Session") {
                appModel.timer.stop()
            }
            .keyboardShortcut(".", modifiers: .command)
        } else if appModel.settingsStore.settings.hasCompletedOnboarding {
            Menu("Start Session") {
                ForEach(SessionPreset.allCases) { preset in
                    Button(appModel.presetTitle(preset)) {
                        appModel.startSession(preset)
                    }
                }
            }
        } else {
            Text("Finish onboarding to focus")
                .foregroundStyle(.secondary)
        }

        Divider()
        Button("Open Study Block") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }
        SettingsLink {
            Text("Settings…")
        }
        Divider()
        Button("Quit Study Block") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
