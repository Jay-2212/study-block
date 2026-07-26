import Foundation

enum AppEscalationStage: Equatable {
    case nudge
    case snoozed(until: Date)
    case allowance(until: Date)
    case warning(until: Date)
    case quitRequested
    case quitFailed
}

struct AppEscalationState: Equatable, Identifiable {
    let app: AppChoice
    var stage: AppEscalationStage

    var id: String { app.bundleIdentifier }
}

enum AppEscalationEvent: Equatable {
    case showNudge(AppEscalationState)
    case showWarning(AppEscalationState)
    case requestQuit(AppEscalationState)
    case clear(bundleIdentifier: String)
}

enum AllowanceValidationError: LocalizedError, Equatable {
    case invalid
    case exceedsLimit

    var errorDescription: String? {
        switch self {
        case .invalid:
            "Enter a positive number of minutes."
        case .exceedsLimit:
            "That timer is too long. Choose a shorter one."
        }
    }
}

struct AppEscalationStateMachine {
    private(set) var states: [String: AppEscalationState] = [:]

    mutating func observe(_ app: AppChoice) -> AppEscalationEvent? {
        if let state = states[app.bundleIdentifier] {
            return state.stage == .nudge ? .showNudge(state) : nil
        }
        let state = AppEscalationState(app: app, stage: .nudge)
        states[app.bundleIdentifier] = state
        return .showNudge(state)
    }

    mutating func snooze(
        bundleIdentifier: String,
        now: Date,
        duration: TimeInterval = 5 * 60
    ) {
        update(bundleIdentifier) { $0.stage = .snoozed(until: now.addingTimeInterval(duration)) }
    }

    mutating func beginAllowance(
        bundleIdentifier: String,
        minutes: Int,
        now: Date,
        maximumMinutes: Int = 15
    ) throws {
        guard minutes > 0 else { throw AllowanceValidationError.invalid }
        guard minutes <= maximumMinutes else {
            throw AllowanceValidationError.exceedsLimit
        }
        update(bundleIdentifier) {
            $0.stage = .allowance(
                until: now.addingTimeInterval(TimeInterval(minutes * 60))
            )
        }
    }

    mutating func tick(
        now: Date,
        warningDuration: TimeInterval = 30,
        isAppRunning: (String) -> Bool
    ) -> [AppEscalationEvent] {
        var events: [AppEscalationEvent] = []

        for bundleIdentifier in states.keys.sorted() {
            guard var state = states[bundleIdentifier] else { continue }
            guard isAppRunning(bundleIdentifier) else {
                states.removeValue(forKey: bundleIdentifier)
                events.append(.clear(bundleIdentifier: bundleIdentifier))
                continue
            }

            switch state.stage {
            case .snoozed(let until) where now >= until:
                state.stage = .nudge
                states[bundleIdentifier] = state
                events.append(.showNudge(state))
            case .allowance(let until) where now >= until:
                state.stage = .warning(until: now.addingTimeInterval(warningDuration))
                states[bundleIdentifier] = state
                events.append(.showWarning(state))
            case .warning(let until) where now >= until:
                state.stage = .quitRequested
                states[bundleIdentifier] = state
                events.append(.requestQuit(state))
            default:
                break
            }
        }
        return events
    }

    mutating func markQuitFailed(bundleIdentifier: String) -> AppEscalationState? {
        update(bundleIdentifier) { $0.stage = .quitFailed }
        return states[bundleIdentifier]
    }

    mutating func remove(bundleIdentifier: String) {
        states.removeValue(forKey: bundleIdentifier)
    }

    mutating func removeAll() {
        states.removeAll()
    }

    private mutating func update(
        _ bundleIdentifier: String,
        change: (inout AppEscalationState) -> Void
    ) {
        guard var state = states[bundleIdentifier] else { return }
        change(&state)
        states[bundleIdentifier] = state
    }
}
