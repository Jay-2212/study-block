import SwiftUI

/// Menu-bar commands for starting and stopping a session, mirroring
/// `MenuBarContentView`'s vocabulary. Kept as a dedicated `View` (rather than
/// reading `appModel` inline in the `Commands` builder) so state changes on
/// `AppModel` reliably drive menu-item enablement the same way a normal view
/// body would.
struct SessionCommands: View {
    let appModel: AppModel

    var body: some View {
        Button("Start Session") {
            appModel.startSession()
        }
        .disabled(
            appModel.timer.isRunning
                || !appModel.settingsStore.settings.hasCompletedOnboarding
        )
        .keyboardShortcut(.return, modifiers: [.command])

        Button("Stop Session") {
            appModel.timer.stop()
        }
        .disabled(!appModel.timer.isRunning)
        .keyboardShortcut(".", modifiers: [.command])
    }
}
