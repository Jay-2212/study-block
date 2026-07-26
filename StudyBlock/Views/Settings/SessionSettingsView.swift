import SwiftUI

struct SessionSettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Form {
            Section("Session presets") {
                ForEach(0..<3, id: \.self) { index in
                    Stepper(
                        value: presetBinding(index),
                        in: 1...480,
                        step: 5
                    ) {
                        HStack {
                            Label(
                                "Preset \(index + 1)",
                                systemImage: "\(index + 1).circle"
                            )
                            Spacer()
                            Text(
                                "\(appModel.settingsStore.settings.sessionPresetMinutes[index]) min"
                            )
                            .monospacedDigit()
                        }
                    }
                }
                Text("Open-ended is always available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Defaults") {
                Toggle("Strict mode", isOn: strictModeBinding)
                Text("Disables snooze, caps app timers at 5 minutes, and shortens the final warning to 10 seconds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle(
                    "Do Not Disturb during sessions",
                    isOn: doNotDisturbBinding
                )
                Text("An existing Focus is preserved. Study Block restores only the state it changed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func presetBinding(_ index: Int) -> Binding<Int> {
        Binding(
            get: {
                appModel.settingsStore.settings.sessionPresetMinutes[index]
            },
            set: { value in
                var settings = appModel.settingsStore.settings
                settings.sessionPresetMinutes[index] = value
                appModel.settingsStore.save(settings)
            }
        )
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
