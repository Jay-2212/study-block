import Foundation

@MainActor
protocol WebEnforcementProvider: AnyObject {
    func start(
        policy: WebEnforcementPolicy,
        sessionStartDate: Date,
        sessionEndDate: Date?
    )
    func stop()
}
