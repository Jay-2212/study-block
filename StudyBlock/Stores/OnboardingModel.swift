import Foundation
import Observation

@MainActor
@Observable
final class OnboardingModel {
    var step = 0
    var draft: OnboardingDraft
    var discoveredDomains: [String] = []
    var manualWhitelistEntry = ""
    var manualBlacklistEntry = ""
    var statusMessage: String?
    var isDiscoveringChrome = false

    private let settingsStore: SettingsStore
    private let chromeDiscovery = ChromeTabDiscoveryService()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        draft = OnboardingDraft(settings: settingsStore.settings)
    }

    func discoverChromeDomains() {
        isDiscoveringChrome = true
        defer { isDiscoveringChrome = false }
        do {
            discoveredDomains = try chromeDiscovery.discoverDomains()
            statusMessage = "Choose the Chrome domains you use for focused work."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func toggleWhitelistedDomain(_ domain: String) {
        guard !draft.blacklistedDomains.contains(domain) else {
            statusMessage = "\(domain) is blacklisted. Remove it there first."
            return
        }
        if draft.whitelistedDomains.remove(domain) == nil {
            draft.whitelistedDomains.insert(domain)
        }
    }

    func toggleBlacklistedDomain(_ domain: String) {
        guard !draft.whitelistedDomains.contains(domain) else {
            statusMessage = "\(domain) is whitelisted. Remove it there first."
            return
        }
        if draft.blacklistedDomains.remove(domain) == nil {
            draft.blacklistedDomains.insert(domain)
        }
    }

    func addManualWhitelist() {
        addDomain(manualWhitelistEntry, toWhitelist: true)
        manualWhitelistEntry = ""
    }

    func addManualBlacklist() {
        addDomain(manualBlacklistEntry, toWhitelist: false)
        manualBlacklistEntry = ""
    }

    func addApp(_ app: AppChoice, toWhitelist: Bool) {
        let conflicting = toWhitelist
            ? draft.blacklistedApps.contains(app)
            : draft.whitelistedApps.contains(app)
        guard !conflicting else {
            statusMessage = "\(app.name) is already in the other list."
            return
        }
        if toWhitelist {
            draft.whitelistedApps.insert(app)
        } else {
            draft.blacklistedApps.insert(app)
        }
    }

    func toggleApp(_ app: AppChoice, inWhitelist: Bool) {
        if inWhitelist {
            if draft.whitelistedApps.remove(app) == nil {
                addApp(app, toWhitelist: true)
            }
        } else if draft.blacklistedApps.remove(app) == nil {
            addApp(app, toWhitelist: false)
        }
    }

    func complete() {
        var settings = settingsStore.settings
        settings.hasCompletedOnboarding = true
        settings.whitelistedDomains = draft.whitelistedDomains.sorted()
        settings.blacklistedDomains = draft.blacklistedDomains.sorted()
        settings.whitelistedApps = draft.whitelistedApps.sorted { $0.name < $1.name }
        settings.blacklistedApps = draft.blacklistedApps.sorted { $0.name < $1.name }
        settingsStore.save(settings)
    }

    private func addDomain(_ input: String, toWhitelist: Bool) {
        do {
            let domain = try DomainNormalizer.normalize(input)
            if toWhitelist {
                guard !draft.blacklistedDomains.contains(domain) else {
                    statusMessage = "\(domain) is blacklisted. Remove it there first."
                    return
                }
                draft.whitelistedDomains.insert(domain)
            } else {
                guard !draft.whitelistedDomains.contains(domain) else {
                    statusMessage = "\(domain) is whitelisted. Remove it there first."
                    return
                }
                draft.blacklistedDomains.insert(domain)
            }
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
