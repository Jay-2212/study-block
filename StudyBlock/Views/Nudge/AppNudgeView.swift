import SwiftUI

struct AppNudgeView: View {
    @Bindable var coordinator: AppEscalationCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(iconTint, in: Circle())

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
        .studySurface()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
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
                .keyboardShortcut(.cancelAction)
            }
        default:
            EmptyView()
        }
    }

    private var nudgeActions: some View {
        VStack(spacing: 14) {
            Button("Quit Now") {
                coordinator.quitCurrentNow()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if coordinator.canSnooze {
                Button("Give Me 5 Min") {
                    coordinator.snoozeCurrent()
                }
                .keyboardShortcut(.cancelAction)
            }

            HStack(spacing: 8) {
                TextField("Minutes", text: $coordinator.timerInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit { coordinator.beginAllowance() }
                    .accessibilityLabel("Allowance minutes")
                Button("Start Timer") {
                    coordinator.beginAllowance()
                }
            }
            .controlSize(.small)

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
            BigNumberDisplay(
                value: "\(coordinator.warningRemainingSeconds)s",
                size: .compact,
                urgent: true
            )
            Button("Keep App Open") {
                coordinator.bypassWarning()
            }
            .keyboardShortcut(.cancelAction)
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
        switch coordinator.currentState?.stage {
        case .warning, .quitFailed:
            "exclamationmark.triangle.fill"
        default:
            "moon.stars.fill"
        }
    }

    private var iconTint: Color {
        switch coordinator.currentState?.stage {
        case .warning, .quitFailed:
            .orange
        default:
            .accentColor
        }
    }
}
