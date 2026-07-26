import Foundation

struct AppSettings: Codable, Equatable {
    var hasCompletedOnboarding = false
    var whitelistedDomains: [String] = []
    var blacklistedDomains: [String] = []
    var whitelistedApps: [AppChoice] = []
    var blacklistedApps: [AppChoice] = []
    var sessionDurationMinutes = 25
    var strictModeEnabled = false
    var doNotDisturbEnabled = false

    static let empty = AppSettings()

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try values.decodeIfPresent(
            Bool.self,
            forKey: .hasCompletedOnboarding
        ) ?? false
        whitelistedDomains = try values.decodeIfPresent(
            [String].self,
            forKey: .whitelistedDomains
        ) ?? []
        blacklistedDomains = try values.decodeIfPresent(
            [String].self,
            forKey: .blacklistedDomains
        ) ?? []
        whitelistedApps = try values.decodeIfPresent(
            [AppChoice].self,
            forKey: .whitelistedApps
        ) ?? []
        blacklistedApps = try values.decodeIfPresent(
            [AppChoice].self,
            forKey: .blacklistedApps
        ) ?? []
        sessionDurationMinutes = try values.decodeIfPresent(
            Int.self,
            forKey: .sessionDurationMinutes
        ) ?? 25
        strictModeEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .strictModeEnabled
        ) ?? false
        doNotDisturbEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .doNotDisturbEnabled
        ) ?? false
    }
}
