import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Study Block at login", isOn: launchBinding)
                    .disabled(appModel.launchAtLogin.isUpdating)
                if let message = appModel.launchAtLogin.statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Onboarding") {
                Text("Review the original guided setup at any time.")
                    .foregroundStyle(.secondary)
                Button("Run Onboarding Again") {
                    appModel.onboarding.restart()
                    appModel.settingsStore.resetOnboarding()
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
            }

            if let error = appModel.settingsStore.errorMessage {
                Section("Storage") {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { appModel.settingsStore.settings.launchAtLoginEnabled },
            set: { appModel.setLaunchAtLogin($0) }
        )
    }
}
