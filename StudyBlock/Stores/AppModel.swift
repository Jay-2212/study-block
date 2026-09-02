import AppKit
import Observation

@MainActor
@Observable
final class AppModel {
    let settingsStore: SettingsStore
    let sessionHistory: SessionHistoryStore
    let timer: TimerCoordinator
    let onboarding: OnboardingModel
    let appEscalation: AppEscalationCoordinator
    let doNotDisturb: DoNotDisturbService
    let notifications = NotificationService()
    let listIcons = ListIconStore()
    let launchAtLogin = LaunchAtLoginService()
    let allowedDomainEditor = DomainEntryModel()
    let blockedDomainEditor = DomainEntryModel()
    let chromeTabs = ChromeTabPickerStore()
    private(set) var lastBlockedDomain: String?
    private(set) var enforcementMessage: String?
    private(set) var lastCompletionMessage: String?

    @ObservationIgnored private var timerPanelController: FloatingTimerPanelController!
    @ObservationIgnored private var notchOverlayController: NotchOverlayController!
    @ObservationIgnored private var nudgePanelController: NudgePanelController!
    @ObservationIgnored private var webEnforcement: WebEnforcementProvider!
    @ObservationIgnored private let musicBlocking = MusicBlockingService()
    @ObservationIgnored private let blockTracker = SessionBlockTracker()
    @ObservationIgnored private var lifecycleObservers: [NSObjectProtocol] = []
    @ObservationIgnored private let activeSessionPersistence =
        ActiveSessionPersistence()
    @ObservationIgnored private var activeStrictMode = false
    @ObservationIgnored private var isSuspended = false

    init() {
        let settingsStore = SettingsStore()
        let sessionHistory = SessionHistoryStore()
        let timer = TimerCoordinator()
        self.settingsStore = settingsStore
        self.sessionHistory = sessionHistory
        self.timer = timer
        onboarding = OnboardingModel(settingsStore: settingsStore)
        appEscalation = AppEscalationCoordinator()
        doNotDisturb = DoNotDisturbService()
        launchAtLogin.refreshRegistrationIfNeeded()
        onboarding.onRequestNotificationPermission = { [weak notifications] in
            notifications?.requestAuthorization()
        }

        timerPanelController = FloatingTimerPanelController(timer: timer)
        notchOverlayController = NotchOverlayController(timer: timer)
        nudgePanelController = NudgePanelController(coordinator: appEscalation)
        let chromeEnforcement = ChromeTabEnforcementService()
        webEnforcement = chromeEnforcement

        timer.presentationHandler = { [weak self] shouldShow in
            self?.updateIndicatorsVisibility(shouldShow: shouldShow)
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
            self?.blockTracker.recordSite(domain)
        }
        appEscalation.blockHandler = { [weak self] app in
            self?.blockTracker.recordApp(app)
        }
        chromeEnforcement.errorHandler = { [weak self] message in
            self?.enforcementMessage = message
        }
        timer.lifecycleHandler = { [weak self] event in
            guard let self else { return }
            switch event {
            case .started(
                let startDate,
                let endDate,
                let preset,
                let plannedDurationMinutes
            ):
                self.activeSessionPersistence.save(
                    ActiveSessionSnapshot(
                        startDate: startDate,
                        endDate: endDate,
                        preset: preset,
                        plannedDurationMinutes: plannedDurationMinutes
                    )
                )
                self.activeStrictMode = self.settingsStore.settings.strictModeEnabled
                self.lastCompletionMessage = nil
                self.blockTracker.reset()
                self.startSessionResources(
                    startDate: startDate,
                    endDate: endDate
                )
            case .ended(
                let startDate,
                let endDate,
                let preset,
                let plannedDurationMinutes,
                let completed
            ):
                self.activeSessionPersistence.clear()
                self.stopSessionResources()
                if completed {
                    self.sessionHistory.record(
                        StudySessionRecord(
                            startDate: startDate,
                            endDate: endDate,
                            plannedDurationMinutes: plannedDurationMinutes,
                            preset: preset,
                            strictModeEnabled: self.activeStrictMode,
                            blockedSites: self.blockTracker.siteSnapshot(),
                            blockedApps: self.blockTracker.appSnapshot()
                        )
                    )
                    let message = Self.completionMessage(
                        startDate: startDate,
                        endDate: endDate
                    )
                    self.lastCompletionMessage = message
                    self.notifications.notifySessionCompleted(body: message)
                }
            }
        }
        settingsStore.changeHandler = { [weak self] _ in
            self?.applySettingsLive()
        }
        installLifecycleObservers()
        recoverInterruptedSession()
    }

    func startSession(_ preset: SessionPreset? = nil) {
        let selected = preset ?? timer.selectedPreset
        let duration = configuredDuration(for: selected)
        timer.start(preset: selected, durationMinutes: duration)
    }

    func configuredDuration(for preset: SessionPreset) -> Int? {
        guard preset != .openEnded else { return nil }
        let index: Int
        switch preset {
        case .sixty: index = 0
        case .ninety: index = 1
        case .oneTwenty: index = 2
        case .openEnded: return nil
        }
        return settingsStore.settings.sessionPresetMinutes[index]
    }

    func presetTitle(_ preset: SessionPreset) -> String {
        configuredDuration(for: preset).map { "\($0) min" } ?? "Open-ended"
    }

    private static func completionMessage(startDate: Date, endDate: Date) -> String {
        let minutes = max(1, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        let duration = hours > 0
            ? (remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h")
            : "\(minutes)m"
        return "You focused for \(duration). Nice work."
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin.setEnabled(enabled) { [weak self] succeeded in
            guard succeeded else { return }
            self?.settingsStore.updateLaunchAtLogin(enabled)
        }
    }

    func shutdown() {
        timer.terminate()
        stopSessionResources()
        timerPanelController.close()
        notchOverlayController.close()
        nudgePanelController.close()
        removeLifecycleObservers()
    }

    func updateIndicatorsVisibility(shouldShow: Bool? = nil) {
        let visible = shouldShow ?? (timer.isRunning && timer.isPanelVisible)
        if visible && settingsStore.settings.showFloatingTimer {
            timerPanelController.show()
        } else {
            timerPanelController.hide()
        }

        if visible && settingsStore.settings.showNotchIndicator {
            notchOverlayController.show()
        } else {
            notchOverlayController.hide()
        }
    }

    private func startSessionResources(startDate: Date, endDate: Date?) {
        guard !isSuspended else { return }
        let settings = settingsStore.settings
        lastBlockedDomain = nil
        enforcementMessage = nil
        webEnforcement.start(
            policy: WebEnforcementPolicy(
                blacklistedDomains: settings.blacklistedDomains
            ),
            sessionStartDate: startDate,
            sessionEndDate: endDate
        )
        appEscalation.start(
            blockedApps: settings.blacklistedApps,
            strictMode: settings.strictModeEnabled
        )
        musicBlocking.start(
            allowedBundleIdentifiers: Set(
                settings.whitelistedApps.map(\.bundleIdentifier)
            )
        )
        doNotDisturb.start(enabled: settings.doNotDisturbEnabled)
    }

    private func stopSessionResources(releaseDoNotDisturb: Bool = true) {
        webEnforcement.stop()
        appEscalation.stop()
        musicBlocking.stop()
        if releaseDoNotDisturb {
            doNotDisturb.stop()
        }
    }

    private func applySettingsLive() {
        updateIndicatorsVisibility()
        guard timer.isRunning,
              !isSuspended,
              let startDate = timer.sessionStartDate else {
            return
        }
        stopSessionResources(releaseDoNotDisturb: false)
        startSessionResources(
            startDate: startDate,
            endDate: timer.sessionEndDate
        )
    }

    private func installLifecycleObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        lifecycleObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.suspendForSleep() }
            }
        )
        lifecycleObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.resumeAfterWake() }
            }
        )
        lifecycleObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.timer.reconcileTime() }
            }
        )
        lifecycleObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.doNotDisturb.refreshAccessibilityTrust()
                }
            }
        )
        lifecycleObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.shutdown() }
            }
        )
    }

    private func suspendForSleep() {
        guard timer.isRunning else { return }
        isSuspended = true
        timer.suspendForSleep()
        stopSessionResources()
        timerPanelController.hide()
        notchOverlayController.hide()
        nudgePanelController.hide()
    }

    private func resumeAfterWake() {
        guard isSuspended else { return }
        isSuspended = false
        timer.resumeAfterWake()
        guard timer.isRunning, let startDate = timer.sessionStartDate else { return }
        startSessionResources(
            startDate: startDate,
            endDate: timer.sessionEndDate
        )
    }

    private func removeLifecycleObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for observer in lifecycleObservers {
            workspaceCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
    }

    private func recoverInterruptedSession() {
        guard let snapshot = activeSessionPersistence.load() else { return }
        if let endDate = snapshot.endDate, endDate <= Date() {
            sessionHistory.record(
                StudySessionRecord(
                    startDate: snapshot.startDate,
                    endDate: endDate,
                    plannedDurationMinutes: snapshot.plannedDurationMinutes,
                    preset: snapshot.preset,
                    strictModeEnabled: settingsStore.settings.strictModeEnabled
                )
            )
            activeSessionPersistence.clear()
            return
        }
        timer.restore(snapshot)
    }
}
