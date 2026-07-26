import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class TimerCoordinator {
    private(set) var isRunning = false
    private(set) var remainingSeconds = 25 * 60
    private(set) var durationSeconds = 25 * 60
    private(set) var sessionEndDate: Date?
    var isPanelVisible = true

    @ObservationIgnored var presentationHandler: ((Bool) -> Void)?
    @ObservationIgnored var sessionStateHandler: ((Bool, Date?) -> Void)?
    @ObservationIgnored private var timer: Timer?

    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1 - Double(remainingSeconds) / Double(durationSeconds)
    }

    func prepare(minutes: Int) {
        guard !isRunning else { return }
        let seconds = max(1, minutes) * 60
        durationSeconds = seconds
        remainingSeconds = seconds
    }

    func start(minutes: Int) {
        stopTicker()
        durationSeconds = max(1, minutes) * 60
        remainingSeconds = durationSeconds
        sessionEndDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        isRunning = true
        isPanelVisible = true
        presentationHandler?(true)
        sessionStateHandler?(true, sessionEndDate)
        scheduleTicker()
    }

    func stop() {
        stopTicker()
        isRunning = false
        sessionEndDate = nil
        remainingSeconds = durationSeconds
        presentationHandler?(false)
        sessionStateHandler?(false, nil)
    }

    func togglePanelVisibility() {
        guard isRunning else { return }
        isPanelVisible.toggle()
        presentationHandler?(isPanelVisible)
    }

    private func scheduleTicker() {
        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(ticker, forMode: .common)
        timer = ticker
    }

    private func tick() {
        guard let sessionEndDate else { return }
        remainingSeconds = max(0, Int(ceil(sessionEndDate.timeIntervalSinceNow)))
        guard remainingSeconds == 0 else { return }
        stopTicker()
        isRunning = false
        self.sessionEndDate = nil
        presentationHandler?(false)
        sessionStateHandler?(false, nil)
        NSSound.beep()
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }
}
