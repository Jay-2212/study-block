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
                accessibilityRow
            }

            Section("Session-complete notifications") {
                notificationStatusRow
            }
        }
        .formStyle(.grouped)
        .onAppear {
            appModel.notifications.refreshAuthorizationStatus()
            appModel.doNotDisturb.refreshAccessibilityTrust()
        }
    }

    @ViewBuilder
    private var accessibilityRow: some View {
        if appModel.doNotDisturb.isAccessibilityTrusted {
            Label(
                "Accessibility is allowed for Do Not Disturb",
                systemImage: "checkmark.circle"
            )
            .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "Do Not Disturb needs Accessibility",
                    systemImage: "hand.raised"
                )
                Text("Study Block only uses this to turn Focus on for a session. It will not ask again every time you start.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Allow Accessibility…") {
                        appModel.doNotDisturb.promptForAccessibilityAccess()
                    }
                    Button("Open Settings") {
                        appModel.doNotDisturb.openAccessibilitySettings()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var notificationStatusRow: some View {
        switch appModel.notifications.authorizationStatus {
        case .authorized, .provisional:
            Label("Notifications are enabled", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        case .denied:
            VStack(alignment: .leading, spacing: 4) {
                Label(
                    "Notifications are turned off",
                    systemImage: "bell.slash"
                )
                .foregroundStyle(.secondary)
                Text("Enable them in System Settings → Notifications → Study Block.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            HStack {
                Label(
                    "Get notified when a session ends",
                    systemImage: "bell"
                )
                .foregroundStyle(.secondary)
                Spacer()
                Button("Enable") {
                    appModel.notifications.requestAuthorization()
                }
            }
        }
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
            set: { enabled in
                appModel.settingsStore.updateDoNotDisturb(enabled)
                if enabled {
                    appModel.doNotDisturb.prepareDoNotDisturbPermission()
                }
            }
        )
    }
}
