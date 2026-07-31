import Observation
import SwiftUI

struct SitesSettingsView: View {
    @Environment(AppModel.self) private var appModel
    private let allowedEditor = DomainEntryModel()
    private let blockedEditor = DomainEntryModel()

    var body: some View {
        Form {
            DomainListEditor(
                model: allowedEditor,
                title: "Study-site allowlist",
                help: "Study sites always take precedence over the blocklist.",
                domains: appModel.settingsStore.settings.whitelistedDomains,
                onAdd: addAllowedDomain,
                onRemove: removeAllowedDomain
            )

            DomainListEditor(
                model: blockedEditor,
                title: "Website blocklist",
                help: "Google, ChatGPT, and Claude can never be blocked.",
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
        settings.whitelistedDomains.append(domain)
        appModel.settingsStore.save(settings)
        return nil
    }

    private func addBlockedDomain(_ domain: String) -> String? {
        if WebEnforcementPolicy.isPermanentlyAllowed(domain) {
            return "\(domain) is always available."
        }
        if appModel.settingsStore.settings.whitelistedDomains.contains(domain) {
            return "\(domain) is a study site. Remove it from the allowlist first."
        }
        var settings = appModel.settingsStore.settings
        settings.blacklistedDomains.append(domain)
        appModel.settingsStore.save(settings)
        return nil
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

private struct DomainListEditor: View {
    @Bindable var model: DomainEntryModel
    let title: String
    let help: String
    let domains: [String]
    let onAdd: (String) -> String?
    let onRemove: (String) -> Void

    var body: some View {
        Section {
            if domains.isEmpty {
                StudyEmptyState(
                    title: "No sites added",
                    systemImage: "globe",
                    compact: true
                )
            } else {
                ForEach(domains, id: \.self) { domain in
                    HStack {
                        ListIconView(source: .website(domain), size: 20)
                        Text(domain)
                        Spacer()
                        Button {
                            onRemove(domain)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(domain)")
                    }
                }
            }

            HStack {
                TextField("Domain or URL", text: $model.entry)
                    .onSubmit(add)
                Button("Add", action: add)
                    .disabled(
                        model.entry.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
            }

            if let validationMessage = model.validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text(title)
        } footer: {
            Text(help)
        }
    }

    private func add() {
        do {
            let domain = try DomainNormalizer.normalize(model.entry)
            if domains.contains(domain) {
                model.validationMessage = "\(domain) is already listed."
                return
            }
            model.validationMessage = onAdd(domain)
            guard model.validationMessage == nil else { return }
            model.entry = ""
        } catch {
            model.validationMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
private final class DomainEntryModel {
    var entry = ""
    var validationMessage: String?
}
