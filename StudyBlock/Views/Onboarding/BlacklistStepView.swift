import SwiftUI

struct BlacklistStepView: View {
    @Bindable var model: OnboardingModel

    private let columns = [
        GridItem(.adaptive(minimum: 210), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose obvious distractions")
                        .font(.largeTitle.bold())
                    Text("During a focus session, these sites are redirected and these apps receive escalating nudges.")
                        .foregroundStyle(.secondary)
                }

                distractingSites
                distractingApps

                Label(
                    "Google, ChatGPT, and Claude always remain available.",
                    systemImage: "checkmark.shield"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .padding(32)
            .frame(maxWidth: 780, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var distractingSites: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distracting websites")
                .font(.headline)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(SitePreset.distracting) { site in
                    SelectionRow(
                        title: site.name,
                        subtitle: site.domain,
                        icon: .website(site.domain),
                        isSelected: model.draft.blacklistedDomains.contains(site.domain)
                    ) {
                        model.toggleBlacklistedDomain(site.domain)
                    }
                }
            }

            HStack {
                TextField("Add a domain or URL", text: $model.manualBlacklistEntry)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { model.addManualBlacklist() }
                Button("Add") {
                    model.addManualBlacklist()
                }
                .disabled(model.manualBlacklistEntry.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(18)
        .studySurface()
    }

    private var distractingApps: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Distracting apps and games")
                    .font(.headline)
                Spacer()
                Button("Choose App or Game…") {
                    if let app = ApplicationPickerService.chooseApplication() {
                        model.addApp(app, toWhitelist: false)
                    }
                }
            }

            if model.draft.blacklistedApps.isEmpty {
                Text("No apps selected. You can add these later in Settings.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(model.draft.blacklistedApps.sorted { $0.name < $1.name }) { app in
                        SelectionRow(
                            title: app.name,
                            subtitle: app.bundleIdentifier,
                            icon: .application(app.bundleIdentifier),
                            isSelected: true
                        ) {
                            model.toggleApp(app, inWhitelist: false)
                        }
                    }
                }
            }
        }
    }
}
