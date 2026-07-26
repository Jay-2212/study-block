import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppEscalationCoordinator {
    private(set) var currentState: AppEscalationState?
    private(set) var warningRemainingSeconds = 0
    private(set) var isStrictMode = false
    var timerInput = ""
    var validationMessage: String?

    var canSnooze: Bool { !isStrictMode }
    var maximumAllowanceMinutes: Int { isStrictMode ? 5 : 15 }
    var warningDuration: TimeInterval { isStrictMode ? 10 : 30 }

    @ObservationIgnored var presentationHandler: ((Bool) -> Void)?
    @ObservationIgnored private let workspaceMonitor = WorkspaceMonitor()
    @ObservationIgnored private let terminationService = AppTerminationService()
    @ObservationIgnored private var stateMachine = AppEscalationStateMachine()
    @ObservationIgnored private var blockedApps: [String: AppChoice] = [:]
    @ObservationIgnored private var ticker: Timer?

    init() {
        workspaceMonitor.activationHandler = { [weak self] app in
            self?.handleActivation(app)
        }
    }

    func start(blockedApps: [AppChoice], strictMode: Bool) {
        stop()
        isStrictMode = strictMode
        self.blockedApps = Dictionary(
            uniqueKeysWithValues: blockedApps
                .filter(Self.isSafeTarget)
                .map { ($0.bundleIdentifier, $0) }
        )
        guard !self.blockedApps.isEmpty else { return }

        workspaceMonitor.start()
        let ticker = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        workspaceMonitor.stop()
        blockedApps.removeAll()
        stateMachine.removeAll()
        isStrictMode = false
        currentState = nil
        warningRemainingSeconds = 0
        timerInput = ""
        validationMessage = nil
        presentationHandler?(false)
    }

    func snoozeCurrent() {
        guard canSnooze, let currentState else { return }
        stateMachine.snooze(
            bundleIdentifier: currentState.app.bundleIdentifier,
            now: Date()
        )
        dismissPrompt()
    }

    func beginAllowance() {
        guard let currentState,
              let minutes = Int(timerInput.trimmingCharacters(in: .whitespaces))
        else {
            validationMessage = AllowanceValidationError.invalid.localizedDescription
            return
        }

        do {
            try stateMachine.beginAllowance(
                bundleIdentifier: currentState.app.bundleIdentifier,
                minutes: minutes,
                now: Date(),
                maximumMinutes: maximumAllowanceMinutes
            )
            dismissPrompt()
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    func quitCurrentNow() {
        guard let currentState else { return }
        requestQuit(currentState)
    }

    func bypassWarning() {
        guard let currentState else { return }
        stateMachine.remove(bundleIdentifier: currentState.app.bundleIdentifier)
        dismissPrompt()
    }

    func closeFailure() {
        guard let currentState else { return }
        stateMachine.remove(bundleIdentifier: currentState.app.bundleIdentifier)
        dismissPrompt()
    }

    private func handleActivation(_ runningApplication: NSRunningApplication) {
        guard let bundleIdentifier = runningApplication.bundleIdentifier,
              let app = blockedApps[bundleIdentifier],
              let event = stateMachine.observe(app)
        else {
            return
        }
        handle(event)
    }

    private func tick() {
        let now = Date()
        let events = stateMachine.tick(
            now: now,
            warningDuration: warningDuration,
            isAppRunning: terminationService.isRunning
        )
        events.forEach(handle)

        if case .warning(let until) = currentState?.stage {
            warningRemainingSeconds = max(
                0,
                Int(ceil(until.timeIntervalSince(now)))
            )
        }
    }

    private func handle(_ event: AppEscalationEvent) {
        switch event {
        case .showNudge(let state):
            show(state)
        case .showWarning(let state):
            warningRemainingSeconds = Int(warningDuration)
            show(state)
        case .requestQuit(let state):
            currentState = state
            requestQuit(state)
        case .clear(let bundleIdentifier):
            guard currentState?.app.bundleIdentifier == bundleIdentifier else { return }
            dismissPrompt()
        }
    }

    private func requestQuit(_ state: AppEscalationState) {
        guard Self.isSafeTarget(state.app) else {
            validationMessage = "Study Block can never quit itself."
            return
        }
        terminationService.requestQuit(
            bundleIdentifier: state.app.bundleIdentifier
        ) { [weak self] succeeded in
            guard let self else { return }
            if succeeded {
                self.stateMachine.remove(
                    bundleIdentifier: state.app.bundleIdentifier
                )
                self.dismissPrompt()
            } else if let failed = self.stateMachine.markQuitFailed(
                bundleIdentifier: state.app.bundleIdentifier
            ) {
                self.show(failed)
            }
        }
    }

    private func show(_ state: AppEscalationState) {
        currentState = state
        timerInput = ""
        validationMessage = nil
        presentationHandler?(true)
    }

    private func dismissPrompt() {
        currentState = nil
        warningRemainingSeconds = 0
        timerInput = ""
        validationMessage = nil
        presentationHandler?(false)
    }

    private static func isSafeTarget(_ app: AppChoice) -> Bool {
        app.bundleIdentifier != AppTerminationService.studyBlockBundleIdentifier
            && app.bundleIdentifier != Bundle.main.bundleIdentifier
            && app.bundleIdentifier != "com.google.Chrome"
    }
}
