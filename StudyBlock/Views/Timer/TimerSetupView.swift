import SwiftUI

struct TimerSetupView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: appModel.timer.isRunning ? "timer" : "checkmark.shield")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text(appModel.timer.isRunning ? "Focus session" : "You're ready to focus")
                    .font(.largeTitle.bold())
                Text(
                    appModel.timer.isRunning
                        ? appModel.timer.formattedTime
                        : "Choose how long you want to focus"
                )
                .font(appModel.timer.isRunning ? .system(size: 64, weight: .semibold, design: .rounded) : .title2)
                .monospacedDigit()
                .foregroundStyle(appModel.timer.isRunning ? .primary : .secondary)

                if appModel.timer.isRunning {
                    Text(appModel.timer.isOpenEnded ? "elapsed" : "remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }

            if appModel.timer.isRunning && !appModel.timer.isOpenEnded {
                ProgressView(value: appModel.timer.progress)
                    .frame(width: 360)
            }

            if !appModel.timer.isRunning {
                Picker("Session length", selection: presetBinding) {
                    ForEach(SessionPreset.allCases) { preset in
                        Text(appModel.presetTitle(preset)).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 500)
                .accessibilityLabel("Session length")
            }

            HStack(spacing: 12) {
                if appModel.timer.isRunning {
                    Button("Stop Session", role: .destructive) {
                        appModel.timer.stop()
                    }
                    .buttonStyle(.borderedProminent)

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
                    .keyboardShortcut(.return)

                    SettingsLink {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .controlSize(.large)
                }
            }

            if appModel.timer.isRunning {
                enforcementStatus
                sessionModeStatus
            } else {
                VStack(spacing: 8) {
                    Text("Blocked Chrome tabs and distracting apps are watched only while a session runs.")
                    if let message = appModel.doNotDisturb.statusMessage {
                        Label(message, systemImage: "moon")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
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
