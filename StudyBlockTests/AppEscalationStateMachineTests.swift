import XCTest
@testable import StudyBlock

final class AppEscalationStateMachineTests: XCTestCase {
    private let app = AppChoice(
        name: "Harmless Test App",
        bundleIdentifier: "com.example.harmless"
    )

    func testFullEscalationOrder() throws {
        var machine = AppEscalationStateMachine()
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(
            machine.observe(app),
            .showNudge(AppEscalationState(app: app, stage: .nudge))
        )

        machine.snooze(bundleIdentifier: app.bundleIdentifier, now: start)
        XCTAssertTrue(machine.tick(
            now: start.addingTimeInterval(299),
            isAppRunning: { _ in true }
        ).isEmpty)

        let returningNudge = machine.tick(
            now: start.addingTimeInterval(300),
            isAppRunning: { _ in true }
        )
        XCTAssertEqual(returningNudge.count, 1)

        try machine.beginAllowance(
            bundleIdentifier: app.bundleIdentifier,
            minutes: 1,
            now: start.addingTimeInterval(300)
        )
        let warning = machine.tick(
            now: start.addingTimeInterval(360),
            isAppRunning: { _ in true }
        )
        XCTAssertEqual(warning.count, 1)

        let quit = machine.tick(
            now: start.addingTimeInterval(390),
            isAppRunning: { _ in true }
        )
        XCTAssertEqual(quit.count, 1)
        guard case .requestQuit = quit[0] else {
            return XCTFail("Expected a cooperative quit request")
        }
    }

    func testAllowanceAboveHiddenCapIsRejected() {
        var machine = AppEscalationStateMachine()
        _ = machine.observe(app)
        XCTAssertThrowsError(
            try machine.beginAllowance(
                bundleIdentifier: app.bundleIdentifier,
                minutes: 16,
                now: Date()
            )
        ) { error in
            XCTAssertEqual(error as? AllowanceValidationError, .exceedsLimit)
        }
    }
}
