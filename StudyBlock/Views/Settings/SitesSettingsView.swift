import SwiftUI

struct SitesSettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Form {
            ChromeTabPickerView(
                picker: appModel.chromeTabs,
                allowed: Set(appModel.settingsStore.settings.whitelistedDomains),
                blocked: Set(appModel.settingsStore.settings.blacklistedDomains),
                onAllow: { _ = addAllowedDomain($0) },
                onBlock: setBlockedDomain
            )

            DomainListEditor(
                model: appModel.allowedDomainEditor,
                title: "Study-site allowlist",
                help: "Study sites always take precedence over the blocklist.",
                domains: appModel.settingsStore.settings.whitelistedDomains,
                onAdd: addAllowedDomain,
                onRemove: removeAllowedDomain
            )

            DomainListEditor(
                model: appModel.blockedDomainEditor,
                title: "Website blocklist",
                help: "Google, ChatGPT, and Claude are suggested as work sites, but they can be blocked if you add them here.",
                domains: appModel.settingsStore.settings.blacklistedDomains,
                onAdd: addBlockedDomain,
                onRemove: removeBlockedDomain
            )

            Section("Distracting apps") {
                appRows(
                    appModel.settingsStore.settings.blacklistedApps,
                    remove: removeBlockedApp
                )
                Button("Choose App or Game…") {
                    guard let app = ApplicationPickerService.chooseApplication()
                    else {
                        return
                    }
                    var settings = appModel.settingsStore.settings
                    settings.whitelistedApps.removeAll {
                        $0.bundleIdentifier == app.bundleIdentifier
                    }
                    if !settings.blacklistedApps.contains(app) {
                        settings.blacklistedApps.append(app)
                    }
                    appModel.settingsStore.save(settings)
                }
            }

            Section("Allowed apps") {
                appRows(
                    appModel.settingsStore.settings.whitelistedApps,
                    remove: removeAllowedApp
                )
                Button("Choose Allowed App…") {
                    guard let app = ApplicationPickerService.chooseApplication()
                    else {
                        return
                    }
                    var settings = appModel.settingsStore.settings
                    settings.blacklistedApps.removeAll {
                        $0.bundleIdentifier == app.bundleIdentifier
                    }
                    if !settings.whitelistedApps.contains(app) {
                        settings.whitelistedApps.append(app)
                    }
                    appModel.settingsStore.save(settings)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { appModel.chromeTabs.start() }
        .onDisappear { appModel.chromeTabs.stop() }
    }

    @ViewBuilder
    private func appRows(
        _ apps: [AppChoice],
        remove: @escaping (AppChoice) -> Void
    ) -> some View {
        if apps.isEmpty {
            StudyEmptyState(
                title: "None selected",
                systemImage: "app.dashed",
                compact: true
            )
        } else {
            ForEach(apps.sorted { $0.name < $1.name }) { app in
                HStack {
                    ListIconView(
                        source: .application(app.bundleIdentifier),
                        size: 22
                    )
                    Text(app.name)
                    Spacer()
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        remove(app)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(app.name)")
                }
            }
        }
    }

    private func addAllowedDomain(_ domain: String) -> String? {
        var settings = appModel.settingsStore.settings
        settings.blacklistedDomains.removeAll { $0 == domain }
        if !settings.whitelistedDomains.contains(domain) {
            settings.whitelistedDomains.append(domain)
        }
        appModel.settingsStore.save(settings)
        return nil
    }

    private func addBlockedDomain(_ domain: String) -> String? {
        if appModel.settingsStore.settings.whitelistedDomains.contains(domain) {
            return "\(domain) is a study site. Remove it from the allowlist first."
        }
        setBlockedDomain(domain)
        return nil
    }

    private func setBlockedDomain(_ domain: String) {
        var settings = appModel.settingsStore.settings
        settings.whitelistedDomains.removeAll { $0 == domain }
        if !settings.blacklistedDomains.contains(domain) {
            settings.blacklistedDomains.append(domain)
        }
        appModel.settingsStore.save(settings)
    }

    private func removeAllowedDomain(_ domain: String) {
        var settings = appModel.settingsStore.settings
        settings.whitelistedDomains.removeAll { $0 == domain }
        appModel.settingsStore.save(settings)
    }

    private func removeBlockedDomain(_ domain: String) {
        var settings = appModel.settingsStore.settings
        settings.blacklistedDomains.removeAll { $0 == domain }
        appModel.settingsStore.save(settings)
    }

    private func removeBlockedApp(_ app: AppChoice) {
        var settings = appModel.settingsStore.settings
        settings.blacklistedApps.removeAll {
            $0.bundleIdentifier == app.bundleIdentifier
        }
        appModel.settingsStore.save(settings)
    }

    private func removeAllowedApp(_ app: AppChoice) {
        var settings = appModel.settingsStore.settings
        settings.whitelistedApps.removeAll {
            $0.bundleIdentifier == app.bundleIdentifier
        }
        appModel.settingsStore.save(settings)
    }
}
