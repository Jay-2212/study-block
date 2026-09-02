import SwiftUI

struct TimerSetupView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: appModel.timer.isRunning ? "timer" : "checkmark.shield")
                .font(.system(size: appModel.timer.isRunning ? 40 : 36, weight: .medium))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text(appModel.timer.isRunning ? "Focus session" : "You're ready to focus")
                    .font(.title.weight(.semibold))
                if appModel.timer.isRunning {
                    BigNumberDisplay(value: appModel.timer.formattedTime, size: .large)
                    Text(appModel.timer.isOpenEnded ? "elapsed" : "remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }

            if appModel.timer.isRunning && !appModel.timer.isOpenEnded {
                ProgressView(value: appModel.timer.progress)
                    .frame(width: 320)
            }

            if !appModel.timer.isRunning {
                Picker("Session length", selection: presetBinding) {
                    ForEach(SessionPreset.allCases) { preset in
                        Text(appModel.presetTitle(preset)).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 440)
                .accessibilityLabel("Session length")
            }

            HStack(spacing: 12) {
                if appModel.timer.isRunning {
                    Button("Stop Session", role: .destructive) {
                        appModel.timer.stop()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(".", modifiers: .command)

                    Button(
                        appModel.timer.isPanelVisible ? "Hide Floating Timer" : "Show Floating Timer"
                    ) {
                        appModel.timer.togglePanelVisibility()
                    }
                } else {
                    Button("Start \(appModel.presetTitle(appModel.timer.selectedPreset)) Session") {
                        appModel.startSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }

            if appModel.timer.isRunning {
                enforcementStatus
                sessionModeStatus
            } else {
                idleStatus
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                }
                .help("Settings")
            }
        }
        .animation(.snappy, value: appModel.timer.isRunning)
    }

    private var presetBinding: Binding<SessionPreset> {
        Binding(
            get: { appModel.timer.selectedPreset },
            set: { appModel.timer.selectedPreset = $0 }
        )
    }

    @ViewBuilder
    private var enforcementStatus: some View {
        if let message = appModel.enforcementMessage {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.orange)
        } else if let domain = appModel.lastBlockedDomain {
            Label("\(domain) redirected back to focus", systemImage: "shield.checkered")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            Label("Chrome and distracting apps are being watched", systemImage: "shield")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var idleStatus: some View {
        let completion = appModel.lastCompletionMessage
        let dndMessage = appModel.doNotDisturb.statusMessage
        let needsNotificationPrompt =
            appModel.notifications.authorizationStatus == .notDetermined

        if completion != nil || dndMessage != nil || needsNotificationPrompt {
            VStack(spacing: 8) {
                if let completion {
                    Label(completion, systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
                if let dndMessage {
                    Label(dndMessage, systemImage: "moon")
                }
                notificationPrimingRow
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var notificationPrimingRow: some View {
        if appModel.notifications.authorizationStatus == .notDetermined {
            HStack(spacing: 8) {
                Label(
                    "Get notified when a session ends",
                    systemImage: "bell"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                Button("Enable") {
                    appModel.notifications.requestAuthorization()
                }
                .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var sessionModeStatus: some View {
        if appModel.settingsStore.settings.strictModeEnabled {
            Label(
                "Strict mode: snooze disabled and escalation shortened",
                systemImage: "lock.fill"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        if let message = appModel.doNotDisturb.statusMessage {
            Label(message, systemImage: "moon.fill")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
