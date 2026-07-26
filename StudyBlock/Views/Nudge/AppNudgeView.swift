import SwiftUI

struct AppNudgeView: View {
    @Bindable var coordinator: AppEscalationCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.tint)

            VStack(spacing: 7) {
                Text(title)
                    .font(.title2.bold())
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .padding(28)
        .frame(width: 410)
        .fixedSize(horizontal: false, vertical: true)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.currentState?.stage {
        case .nudge:
            nudgeActions
        case .warning:
            warningActions
        case .quitRequested:
            ProgressView("Asking the app to quit…")
        case .quitFailed:
            VStack(spacing: 14) {
                Text("The app did not close. Study Block will never force-quit it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Close") {
                    coordinator.closeFailure()
                }
                .keyboardShortcut(.defaultAction)
            }
        default:
            EmptyView()
        }
    }

    private var nudgeActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button("Quit Now") {
                    coordinator.quitCurrentNow()
                }
                .buttonStyle(.borderedProminent)

                if coordinator.canSnooze {
                    Button("Give Me 5 Min") {
                        coordinator.snoozeCurrent()
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Minutes", text: $coordinator.timerInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit { coordinator.beginAllowance() }
                Button("Start Timer") {
                    coordinator.beginAllowance()
                }
            }

            if let message = coordinator.validationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if coordinator.isStrictMode {
                Label(
                    "Strict mode: snooze is off, timers are capped at 5 minutes, and warnings last 10 seconds.",
                    systemImage: "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var warningActions: some View {
        VStack(spacing: 12) {
            Text("\(coordinator.warningRemainingSeconds)s")
                .font(.system(size: 46, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Button("Keep App Open") {
                coordinator.bypassWarning()
            }
        }
    }

    private var title: String {
        switch coordinator.currentState?.stage {
        case .warning:
            "Closing soon"
        case .quitFailed:
            "Couldn’t close the app"
        default:
            "A gentle nudge"
        }
    }

    private var message: String {
        let appName = coordinator.currentState?.app.name ?? "This app"
        return switch coordinator.currentState?.stage {
        case .warning:
            "\(appName) will be asked to quit when the warning ends."
        case .quitFailed:
            "\(appName) may have unsaved work or declined the request."
        default:
            "\(appName) is on your distraction list. Ready to return to your focus session?"
        }
    }

    private var iconName: String {
        coordinator.currentState?.stage.isWarning == true
            ? "exclamationmark.triangle"
            : "moon.stars"
    }
}

private extension AppEscalationStage {
    var isWarning: Bool {
        if case .warning = self { return true }
        return false
    }
}
