import Foundation

@main
enum EscalationSmoke {
    static func main() throws {
        let app = AppChoice(
            name: "Harmless Test App",
            bundleIdentifier: "com.example.harmless"
        )
        let start = Date(timeIntervalSince1970: 1_000)
        var machine = AppEscalationStateMachine()

        guard case .showNudge = machine.observe(app) else {
            fatalError("Expected initial nudge")
        }
        machine.snooze(bundleIdentifier: app.bundleIdentifier, now: start)
        guard case .showNudge = machine.tick(
            now: start.addingTimeInterval(300),
            isAppRunning: { _ in true }
        ).first else {
            fatalError("Expected returning nudge")
        }
        try machine.beginAllowance(
            bundleIdentifier: app.bundleIdentifier,
            minutes: 1,
            now: start.addingTimeInterval(300)
        )
        guard case .showWarning = machine.tick(
            now: start.addingTimeInterval(360),
            isAppRunning: { _ in true }
        ).first else {
            fatalError("Expected warning")
        }
        guard case .requestQuit = machine.tick(
            now: start.addingTimeInterval(390),
            isAppRunning: { _ in true }
        ).first else {
            fatalError("Expected quit request")
        }

        var rejected = false
        var capped = AppEscalationStateMachine()
        _ = capped.observe(app)
        do {
            try capped.beginAllowance(
                bundleIdentifier: app.bundleIdentifier,
                minutes: 16,
                now: start
            )
        } catch AllowanceValidationError.exceedsLimit {
            rejected = true
        }
        guard rejected else { fatalError("16-minute timer must be rejected") }

        var strict = AppEscalationStateMachine()
        _ = strict.observe(app)
        do {
            try strict.beginAllowance(
                bundleIdentifier: app.bundleIdentifier,
                minutes: 6,
                now: start,
                maximumMinutes: 5
            )
            fatalError("Strict mode must reject timers above 5 minutes")
        } catch AllowanceValidationError.exceedsLimit {
            // Expected.
        }
        try strict.beginAllowance(
            bundleIdentifier: app.bundleIdentifier,
            minutes: 1,
            now: start,
            maximumMinutes: 5
        )
        guard case .showWarning = strict.tick(
            now: start.addingTimeInterval(60),
            warningDuration: 10,
            isAppRunning: { _ in true }
        ).first else {
            fatalError("Expected strict warning")
        }
        guard case .requestQuit = strict.tick(
            now: start.addingTimeInterval(70),
            warningDuration: 10,
            isAppRunning: { _ in true }
        ).first else {
            fatalError("Expected strict cooperative quit")
        }
        print("App escalation smoke checks passed.")
    }
}
