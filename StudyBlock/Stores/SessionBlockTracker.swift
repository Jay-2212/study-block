import Foundation
import Observation

@MainActor
@Observable
final class SessionBlockTracker {
    private(set) var siteCounts: [String: Int] = [:]
    private(set) var appCounts: [String: (name: String, count: Int)] = [:]

    func reset() {
        siteCounts = [:]
        appCounts = [:]
    }

    func recordSite(_ domain: String) {
        siteCounts[domain, default: 0] += 1
    }

    func recordApp(_ app: AppChoice) {
        let current = appCounts[app.bundleIdentifier]?.count ?? 0
        appCounts[app.bundleIdentifier] = (app.name, current + 1)
    }

    func siteSnapshot() -> [BlockedSiteStat] {
        siteCounts
            .map { BlockedSiteStat(domain: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.domain < rhs.domain
                }
                return lhs.count > rhs.count
            }
    }

    func appSnapshot() -> [BlockedAppStat] {
        appCounts
            .map {
                BlockedAppStat(
                    name: $0.value.name,
                    bundleIdentifier: $0.key,
                    count: $0.value.count
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.name < rhs.name
                }
                return lhs.count > rhs.count
            }
    }
}
