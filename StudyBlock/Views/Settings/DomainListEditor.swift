import Observation
import SwiftUI

struct DomainListEditor: View {
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
                    .buttonStyle(.bordered)
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
final class DomainEntryModel {
    var entry = ""
    var validationMessage: String?
}
