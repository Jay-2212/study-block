import Foundation

struct AppSettings: Codable, Equatable {
    var hasCompletedOnboarding = false
    var whitelistedDomains: [String] = []
    var blacklistedDomains: [String] = []
    var whitelistedApps: [AppChoice] = []
    var blacklistedApps: [AppChoice] = []
    var sessionDurationMinutes = 25

    static let empty = AppSettings()
}

