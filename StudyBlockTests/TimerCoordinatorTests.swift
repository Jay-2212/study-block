import XCTest
@testable import StudyBlock

@MainActor
final class TimerCoordinatorTests: XCTestCase {
    func testStartingBackToBackSessionsEndsFirstBeforeSecondStarts() {
        let timer = TimerCoordinator()
        var events: [String] = []
        timer.lifecycleHandler = { event in
            switch event {
            case .started:
                events.append("started")
            case .ended:
                events.append("ended")
            }
        }

        timer.start(preset: .sixty, durationMinutes: 60)
        timer.start(preset: .ninety, durationMinutes: 90)

        XCTAssertEqual(events, ["started", "ended", "started"])
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.durationSeconds, 90 * 60)
        timer.terminate()
    }

    func testOpenEndedManualStopIsCompleted() {
        let timer = TimerCoordinator()
        var completed: Bool?
        timer.lifecycleHandler = { event in
            if case .ended(_, _, _, _, let didComplete) = event {
                completed = didComplete
            }
        }

        timer.start(preset: .openEnded)
        timer.reconcileTime()
        timer.stop()

        XCTAssertEqual(completed, timer.displaySeconds > 0)
    }
}
