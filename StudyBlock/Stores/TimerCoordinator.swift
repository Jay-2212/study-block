import AppKit
import Foundation
import Observation

enum SessionLifecycleEvent {
    case started(
        startDate: Date,
        endDate: Date?,
        preset: SessionPreset,
        plannedDurationMinutes: Int?
    )
    case ended(
        startDate: Date,
        endDate: Date,
        preset: SessionPreset,
        plannedDurationMinutes: Int?,
        completed: Bool
    )
}

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
    @ObservationIgnored var lifecycleHandler: ((SessionLifecycleEvent) -> Void)?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var plannedDurationMinutes: Int?

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

    func start(
        preset: SessionPreset? = nil,
        durationMinutes: Int? = nil
    ) {
        if isRunning {
            finish(completed: false, shouldBeep: false)
        }
        stopTicker()
        let preset = preset ?? selectedPreset
        selectedPreset = preset
        let now = Date()
        sessionStartDate = now
        plannedDurationMinutes = preset == .openEnded
            ? nil
            : max(1, durationMinutes ?? preset.durationMinutes ?? 60)
        durationSeconds = plannedDurationMinutes.map { $0 * 60 }
        displaySeconds = durationSeconds ?? 0
        sessionEndDate = durationSeconds.map {
            now.addingTimeInterval(TimeInterval($0))
        }
        isRunning = true
        isPanelVisible = true
        presentationHandler?(true)
        lifecycleHandler?(
            .started(
                startDate: now,
                endDate: sessionEndDate,
                preset: preset,
                plannedDurationMinutes: plannedDurationMinutes
            )
        )
        scheduleTicker()
    }

    func restore(_ snapshot: ActiveSessionSnapshot) {
        guard !isRunning else { return }
        selectedPreset = snapshot.preset
        sessionStartDate = snapshot.startDate
        sessionEndDate = snapshot.endDate
        plannedDurationMinutes = snapshot.plannedDurationMinutes
        durationSeconds = snapshot.plannedDurationMinutes.map { $0 * 60 }
        isRunning = true
        isPanelVisible = true
        reconcileTime()
        guard isRunning else { return }
        presentationHandler?(true)
        lifecycleHandler?(
            .started(
                startDate: snapshot.startDate,
                endDate: snapshot.endDate,
                preset: snapshot.preset,
                plannedDurationMinutes: snapshot.plannedDurationMinutes
            )
        )
        scheduleTicker()
    }

    func stop() {
        let completed = durationSeconds == nil && displaySeconds > 0
        finish(completed: completed, shouldBeep: false)
    }

    func togglePanelVisibility() {
        guard isRunning else { return }
        isPanelVisible.toggle()
        presentationHandler?(isPanelVisible)
    }

    func suspendForSleep() {
        stopTicker()
        presentationHandler?(false)
    }

    func resumeAfterWake() {
        guard isRunning else { return }
        reconcileTime()
        guard isRunning else { return }
        if isPanelVisible {
            presentationHandler?(true)
        }
        scheduleTicker()
    }

    func reconcileTime() {
        guard isRunning else { return }
        tick()
    }

    func terminate() {
        guard isRunning else {
            stopTicker()
            presentationHandler?(false)
            return
        }
        finish(completed: false, shouldBeep: false)
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
        finish(completed: true, shouldBeep: true)
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }

    private func finish(completed: Bool, shouldBeep: Bool) {
        guard isRunning, let startDate = sessionStartDate else {
            stopTicker()
            return
        }
        let endDate = Date()
        let preset = selectedPreset
        let planned = plannedDurationMinutes
        stopTicker()
        isRunning = false
        sessionStartDate = nil
        sessionEndDate = nil
        plannedDurationMinutes = nil
        displaySeconds = preset.durationMinutes.map { $0 * 60 } ?? 0
        presentationHandler?(false)
        lifecycleHandler?(
            .ended(
                startDate: startDate,
                endDate: endDate,
                preset: preset,
                plannedDurationMinutes: planned,
                completed: completed
            )
        )
        if shouldBeep {
            NSSound.beep()
        }
    }
}
