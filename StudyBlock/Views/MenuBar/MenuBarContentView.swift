import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if appModel.timer.isRunning {
            Button("Session: \(appModel.timer.formattedTime)") {}
                .disabled(true)
            Divider()
            Toggle(
                "Floating Timer",
                isOn: Binding(
                    get: { appModel.settingsStore.settings.showFloatingTimer },
                    set: { isEnabled in
                        appModel.settingsStore.updateShowFloatingTimer(isEnabled)
                        appModel.updateIndicatorsVisibility()
                    }
                )
            )
            Toggle(
                "Notch Indicator",
                isOn: Binding(
                    get: { appModel.settingsStore.settings.showNotchIndicator },
                    set: { isEnabled in
                        appModel.settingsStore.updateShowNotchIndicator(isEnabled)
                        appModel.updateIndicatorsVisibility()
                    }
                )
            )
            Divider()
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
