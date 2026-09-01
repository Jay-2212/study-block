import SwiftUI

struct ChromeTabPickerView: View {
    @Bindable var picker: ChromeTabPickerStore
    let allowed: Set<String>
    let blocked: Set<String>
    let onAllow: (String) -> Void
    let onBlock: (String) -> Void

    var body: some View {
        Section {
            if picker.isScanning && picker.domains.isEmpty {
                ProgressView("Reading Chrome tabs…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if picker.domains.isEmpty {
                StudyEmptyState(
                    title: "No Chrome tabs to pick from",
                    systemImage: "network",
                    description: picker.statusMessage
                        ?? "Open Chrome and Study Block will list the sites you can allow or block.",
                    actionTitle: "Scan Chrome Tabs",
                    action: { picker.scan() },
                    compact: true
                )
            } else {
                ForEach(picker.domains, id: \.self) { domain in
                    tabRow(domain)
                }
            }

            if picker.statusMessage != nil, !picker.domains.isEmpty {
                Label(
                    picker.statusMessage ?? "",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        } header: {
            HStack {
                Text("Open Chrome tabs")
                Spacer()
                if !picker.domains.isEmpty {
                    Button("Refresh") {
                        picker.scan()
                    }
                    .disabled(picker.isScanning)
                }
            }
        } footer: {
            Text("Pick from what is already open. You can still type a domain below.")
        }
    }

    private func tabRow(_ domain: String) -> some View {
        HStack(spacing: 10) {
            ListIconView(source: .website(domain), size: 20)
            Text(domain)
            Spacer()
            Button("Allow") { onAllow(domain) }
                .buttonStyle(.bordered)
                .disabled(allowed.contains(domain))
            Button("Block") { onBlock(domain) }
                .buttonStyle(.bordered)
                .disabled(blocked.contains(domain))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: domain))
    }

    private func accessibilityLabel(for domain: String) -> String {
        if allowed.contains(domain) {
            return "\(domain), allowed"
        }
        if blocked.contains(domain) {
            return "\(domain), blocked"
        }
        return domain
    }
}
