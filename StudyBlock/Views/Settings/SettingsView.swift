import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section("Focus timer") {
                Stepper(
                    "\(appModel.settingsStore.settings.sessionDurationMinutes) minutes",
                    value: durationBinding,
                    in: 5...120,
                    step: 5
                )
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

    private var durationBinding: Binding<Int> {
        Binding(
            get: { appModel.settingsStore.settings.sessionDurationMinutes },
            set: { newValue in
                appModel.settingsStore.updateSessionDuration(minutes: newValue)
                appModel.timer.prepare(minutes: newValue)
            }
        )
    }
}
