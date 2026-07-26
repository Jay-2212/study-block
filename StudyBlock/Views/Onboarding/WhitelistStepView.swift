import SwiftUI

struct WhitelistStepView: View {
    @Bindable var model: OnboardingModel

    private let columns = [
        GridItem(.adaptive(minimum: 210), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose what helps you focus")
                        .font(.largeTitle.bold())
                    Text("During a session, allowed sites and apps remain available.")
                        .foregroundStyle(.secondary)
                }

                websiteSection
                appSection
            }
            .padding(32)
            .frame(maxWidth: 780, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var websiteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allowed websites")
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

            ForEach(model.draft.whitelistedDomains.sorted(), id: \.self) { domain in
                if !SitePreset.productive.map(\.domain).contains(domain) {
                    SelectionRow(
                        title: domain,
                        icon: .website(domain),
                        isSelected: true
                    ) {
                        model.toggleWhitelistedDomain(domain)
                    }
                }
            }
        }
        .padding(18)
        .studySurface()
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Allowed apps")
                    .font(.headline)
                Spacer()
                Button("Choose App…") {
                    if let app = ApplicationPickerService.chooseApplication() {
                        model.addApp(app, toWhitelist: true)
                    }
                }
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(AppChoice.productivePresets) { app in
                    SelectionRow(
                        title: app.name,
                        subtitle: app.bundleIdentifier,
                        icon: .application(app.bundleIdentifier),
                        isSelected: model.draft.whitelistedApps.contains(app)
                    ) {
                        model.toggleApp(app, inWhitelist: true)
                    }
                }

                ForEach(customWhitelistedApps) { app in
                    SelectionRow(
                        title: app.name,
                        subtitle: app.bundleIdentifier,
                        icon: .application(app.bundleIdentifier),
                        isSelected: true
                    ) {
                        model.toggleApp(app, inWhitelist: true)
                    }
                }
            }
        }
    }

    private var customWhitelistedApps: [AppChoice] {
        let presets = Set(AppChoice.productivePresets)
        return model.draft.whitelistedApps
            .filter { !presets.contains($0) }
            .sorted { $0.name < $1.name }
    }
}
