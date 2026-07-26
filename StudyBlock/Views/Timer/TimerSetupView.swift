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
                        ? appModel.timer.formattedRemaining
                        : "\(appModel.settingsStore.settings.sessionDurationMinutes)-minute countdown"
                )
                .font(appModel.timer.isRunning ? .system(size: 64, weight: .semibold, design: .rounded) : .title2)
                .monospacedDigit()
                .foregroundStyle(appModel.timer.isRunning ? .primary : .secondary)
            }

            if appModel.timer.isRunning {
                ProgressView(value: appModel.timer.progress)
                    .frame(width: 360)
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
                    Button("Start Focus Session") {
                        appModel.timer.start(
                            minutes: appModel.settingsStore.settings.sessionDurationMinutes
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.return)
                }
            }

            if appModel.timer.isRunning {
                enforcementStatus
            } else {
                Text("Blocked Chrome tabs and distracting apps are watched only while a session runs.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
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
}
