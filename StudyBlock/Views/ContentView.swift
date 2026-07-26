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
    }
}

