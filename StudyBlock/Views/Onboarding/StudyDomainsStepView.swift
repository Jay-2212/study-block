import SwiftUI

struct StudyDomainsStepView: View {
    @Bindable var model: OnboardingModel

    private let columns = [
        GridItem(.adaptive(minimum: 210), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Study Block")
                        .font(.largeTitle.bold())
                    Text("Where do you study or work?")
                        .font(.title2)
                    Text("Choose productive domains from Chrome or add them manually. Only domains are kept.")
                        .foregroundStyle(.secondary)
                }

                chromeSection
                suggestionsSection
                manualSection
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var chromeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Open Chrome tabs", systemImage: "network")
                    .font(.headline)
                Spacer()
                if !model.discoveredDomains.isEmpty {
                    Button("Refresh") {
                        model.discoverChromeDomains()
                    }
                    .disabled(model.isDiscoveringChrome)
                }
            }

            if model.isDiscoveringChrome {
                ProgressView("Reading Chrome domains…")
                    .frame(maxWidth: .infinity)
            } else if model.discoveredDomains.isEmpty {
                StudyEmptyState(
                    title: "Chrome tabs not read yet",
                    systemImage: "network",
                    description: "Study Block will ask to automate Chrome the first time. Manual entry always works too.",
                    actionTitle: "Check Chrome Tabs",
                    action: { model.discoverChromeDomains() },
                    compact: true
                )
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(model.discoveredDomains, id: \.self) { domain in
                        SelectionRow(
                            title: domain,
                            icon: .website(domain),
                            isSelected: model.draft.whitelistedDomains.contains(domain)
                        ) {
                            model.toggleWhitelistedDomain(domain)
                        }
                    }
                }
            }
        }
        .padding(18)
        .studySurface()
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common study and work sites")
                .font(.headline)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(SitePreset.productive) { site in
                    SelectionRow(
                        title: site.name,
                        subtitle: site.domain,
                        icon: .website(site.domain),
                        isSelected: model.draft.whitelistedDomains.contains(site.domain)
                    ) {
                        model.toggleWhitelistedDomain(site.domain)
                    }
                }
            }
        }
    }

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add another site")
                .font(.headline)
            HStack {
                TextField("Paste a domain or full URL", text: $model.manualWhitelistEntry)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { model.addManualWhitelist() }
                Button("Add") {
                    model.addManualWhitelist()
                }
                .disabled(model.manualWhitelistEntry.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
