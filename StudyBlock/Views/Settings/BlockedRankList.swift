import SwiftUI

struct BlockedRankList: View {
    let title: String
    let systemImage: String
    let sites: [BlockedSiteStat]
    let apps: [BlockedAppStat]

    private var isEmpty: Bool { sites.isEmpty && apps.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            if isEmpty {
                StudyEmptyState(
                    title: "Nothing blocked yet",
                    systemImage: systemImage,
                    description: "Sites and apps blocked during sessions will rank here.",
                    compact: true
                )
            } else {
                ForEach(sites.prefix(6)) { site in
                    rankRow(
                        title: site.domain,
                        count: site.count,
                        icon: .website(site.domain)
                    )
                }
                ForEach(apps.prefix(6)) { app in
                    rankRow(
                        title: app.name,
                        count: app.count,
                        icon: .application(app.bundleIdentifier)
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .studySurface(cornerRadius: 12)
    }

    private func rankRow(
        title: String,
        count: Int,
        icon: ListIconSource
    ) -> some View {
        HStack(spacing: 10) {
            ListIconView(source: icon, size: 22)
            Text(title)
                .lineLimit(1)
            Spacer()
            Text(countLabel(count))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(countLabel(count))")
    }

    private func countLabel(_ count: Int) -> String {
        count == 1 ? "1 time" : "\(count) times"
    }
}
