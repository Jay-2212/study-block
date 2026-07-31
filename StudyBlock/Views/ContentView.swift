import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.settingsStore.settings.hasCompletedOnboarding {
                TimerSetupView()
            } else {
                OnboardingFlowView(model: appModel.onboarding)
            }
        }
        .animation(
            .snappy,
            value: appModel.settingsStore.settings.hasCompletedOnboarding
        )
        .alert(
            "Settings Storage Problem",
            isPresented: Binding(
                get: { appModel.settingsStore.pendingErrorAlert != nil },
                set: { isPresented in
                    if !isPresented {
                        appModel.settingsStore.acknowledgeErrorAlert()
                    }
                }
            ),
            presenting: appModel.settingsStore.pendingErrorAlert
        ) { _ in
            Button("OK") { appModel.settingsStore.acknowledgeErrorAlert() }
        } message: { message in
            Text(message)
        }
    }
}

