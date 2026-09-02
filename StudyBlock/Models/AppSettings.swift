import Foundation

struct AppSettings: Codable, Equatable {
    static let defaultSessionPresetMinutes = [60, 90, 120]

    var hasCompletedOnboarding = false
    var whitelistedDomains: [String] = []
    var blacklistedDomains: [String] = []
    var whitelistedApps: [AppChoice] = []
    var blacklistedApps: [AppChoice] = []
    var sessionDurationMinutes = 25
    var sessionPresetMinutes = defaultSessionPresetMinutes
    var strictModeEnabled = false
    var doNotDisturbEnabled = false
    var launchAtLoginEnabled = false
    var showFloatingTimer = true
    var showNotchIndicator = true

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
        sessionPresetMinutes = try values.decodeIfPresent(
            [Int].self,
            forKey: .sessionPresetMinutes
        ) ?? Self.defaultSessionPresetMinutes
        strictModeEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .strictModeEnabled
        ) ?? false
        doNotDisturbEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .doNotDisturbEnabled
        ) ?? false
        launchAtLoginEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .launchAtLoginEnabled
        ) ?? false
        showFloatingTimer = try values.decodeIfPresent(
            Bool.self,
            forKey: .showFloatingTimer
        ) ?? true
        showNotchIndicator = try values.decodeIfPresent(
            Bool.self,
            forKey: .showNotchIndicator
        ) ?? true
    }
}
