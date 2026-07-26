import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section("Session enforcement") {
                Toggle("Strict mode", isOn: strictModeBinding)
                Text("Disables snooze, caps app timers at 5 minutes, and shortens the final warning to 10 seconds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Do Not Disturb during sessions", isOn: doNotDisturbBinding)
                Text("Uses Accessibility to toggle Control Center. An existing Focus is preserved and Study Block restores only what it changed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Onboarding") {
                Text("Review your productive and distracting sites and apps.")
                    .foregroundStyle(.secondary)
                Button("Run Onboarding Again") {
                    appModel.settingsStore.resetOnboarding()
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
            }

            if let error = appModel.settingsStore.errorMessage {
                Section("Storage") {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var strictModeBinding: Binding<Bool> {
        Binding(
            get: { appModel.settingsStore.settings.strictModeEnabled },
            set: { appModel.settingsStore.updateStrictMode($0) }
        )
    }

    private var doNotDisturbBinding: Binding<Bool> {
        Binding(
            get: { appModel.settingsStore.settings.doNotDisturbEnabled },
            set: { appModel.settingsStore.updateDoNotDisturb($0) }
        )
    }
}
