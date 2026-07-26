import Foundation

struct OnboardingDraft {
    var whitelistedDomains: Set<String>
    var blacklistedDomains: Set<String>
    var whitelistedApps: Set<AppChoice>
    var blacklistedApps: Set<AppChoice>

    init(settings: AppSettings) {
        whitelistedDomains = Set(settings.whitelistedDomains)
        blacklistedDomains = Set(settings.blacklistedDomains)
        whitelistedApps = Set(settings.whitelistedApps)
        blacklistedApps = Set(settings.blacklistedApps)
    }
}

