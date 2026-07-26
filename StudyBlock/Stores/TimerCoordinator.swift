import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class TimerCoordinator {
    private(set) var isRunning = false
    private(set) var displaySeconds = 60 * 60
    private(set) var durationSeconds: Int?
    private(set) var sessionStartDate: Date?
    private(set) var sessionEndDate: Date?
    var selectedPreset: SessionPreset = .sixty
    var isPanelVisible = true

    @ObservationIgnored var presentationHandler: ((Bool) -> Void)?
    @ObservationIgnored var sessionStateHandler: ((Bool, Date?, Date?) -> Void)?
    @ObservationIgnored private var timer: Timer?

    var isOpenEnded: Bool {
        isRunning && durationSeconds == nil
    }

    var formattedTime: String {
        let hours = displaySeconds / 3_600
        let minutes = (displaySeconds % 3_600) / 60
        let seconds = displaySeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard let durationSeconds, durationSeconds > 0 else { return 0 }
        return 1 - Double(displaySeconds) / Double(durationSeconds)
    }

    func start(preset: SessionPreset? = nil) {
        stopTicker()
        let preset = preset ?? selectedPreset
        selectedPreset = preset
        let now = Date()
        sessionStartDate = now
        durationSeconds = preset.durationMinutes.map { $0 * 60 }
        displaySeconds = durationSeconds ?? 0
        sessionEndDate = durationSeconds.map {
            now.addingTimeInterval(TimeInterval($0))
        }
        isRunning = true
        isPanelVisible = true
        presentationHandler?(true)
        sessionStateHandler?(true, sessionStartDate, sessionEndDate)
        scheduleTicker()
    }

    func stop() {
        stopTicker()
        isRunning = false
        sessionStartDate = nil
        sessionEndDate = nil
        displaySeconds = selectedPreset.durationMinutes.map { $0 * 60 } ?? 0
        presentationHandler?(false)
        sessionStateHandler?(false, nil, nil)
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
        guard let sessionStartDate else { return }
        if let sessionEndDate {
            displaySeconds = max(0, Int(ceil(sessionEndDate.timeIntervalSinceNow)))
        } else {
            displaySeconds = max(0, Int(Date().timeIntervalSince(sessionStartDate)))
            return
        }
        guard displaySeconds == 0 else { return }
        stopTicker()
        isRunning = false
        self.sessionStartDate = nil
        self.sessionEndDate = nil
        presentationHandler?(false)
        sessionStateHandler?(false, nil, nil)
        NSSound.beep()
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }
}
