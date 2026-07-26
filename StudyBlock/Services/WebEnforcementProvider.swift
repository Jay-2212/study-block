import Foundation

@MainActor
protocol WebEnforcementProvider: AnyObject {
    func start(policy: WebEnforcementPolicy, sessionEndDate: Date)
    func stop()
}
