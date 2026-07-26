import Observation

@MainActor
@Observable
final class AppModel {
    let settingsStore: SettingsStore
    let timer: TimerCoordinator
    let onboarding: OnboardingModel
    let appEscalation: AppEscalationCoordinator
    let doNotDisturb: DoNotDisturbService
    private(set) var lastBlockedDomain: String?
    private(set) var enforcementMessage: String?

    @ObservationIgnored private var timerPanelController: FloatingTimerPanelController!
    @ObservationIgnored private var nudgePanelController: NudgePanelController!
    @ObservationIgnored private var webEnforcement: WebEnforcementProvider!
    @ObservationIgnored private let musicBlocking = MusicBlockingService()

    init() {
        let settingsStore = SettingsStore()
        let timer = TimerCoordinator()
        self.settingsStore = settingsStore
        self.timer = timer
        onboarding = OnboardingModel(settingsStore: settingsStore)
        appEscalation = AppEscalationCoordinator()
        doNotDisturb = DoNotDisturbService()

        timerPanelController = FloatingTimerPanelController(timer: timer)
        nudgePanelController = NudgePanelController(coordinator: appEscalation)
        let chromeEnforcement = ChromeTabEnforcementService()
        webEnforcement = chromeEnforcement

        timer.presentationHandler = { [weak timerPanelController] shouldShow in
            if shouldShow {
                timerPanelController?.show()
            } else {
                timerPanelController?.hide()
            }
        }
        appEscalation.presentationHandler = { [weak nudgePanelController] shouldShow in
            if shouldShow {
                nudgePanelController?.show()
            } else {
                nudgePanelController?.hide()
            }
        }
        chromeEnforcement.redirectHandler = { [weak self] domain in
            self?.lastBlockedDomain = domain
            self?.enforcementMessage = nil
        }
        chromeEnforcement.errorHandler = { [weak self] message in
            self?.enforcementMessage = message
        }
        timer.sessionStateHandler = { [weak self] isRunning, startDate, endDate in
            guard let self else { return }
            if isRunning, let startDate {
                let settings = self.settingsStore.settings
                self.lastBlockedDomain = nil
                self.enforcementMessage = nil
                self.webEnforcement.start(
                    policy: WebEnforcementPolicy(
                        blacklistedDomains: settings.blacklistedDomains
                    ),
                    sessionStartDate: startDate,
                    sessionEndDate: endDate
                )
                self.appEscalation.start(
                    blockedApps: settings.blacklistedApps,
                    strictMode: settings.strictModeEnabled
                )
                self.musicBlocking.start(
                    allowedBundleIdentifiers: Set(
                        settings.whitelistedApps.map(\.bundleIdentifier)
                    )
                )
                self.doNotDisturb.start(enabled: settings.doNotDisturbEnabled)
            } else {
                self.webEnforcement.stop()
                self.appEscalation.stop()
                self.musicBlocking.stop()
                self.doNotDisturb.stop()
            }
        }
    }
}
