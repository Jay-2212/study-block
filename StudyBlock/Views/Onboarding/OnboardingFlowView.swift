import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Group {
                switch model.step {
                case 0:
                    StudyDomainsStepView(model: model)
                case 1:
                    WhitelistStepView(model: model)
                default:
                    BlacklistStepView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            footer
        }
        .background(.background)
    }

    private var header: some View {
        HStack {
            Label("Study Block", systemImage: "shield.lefthalf.filled")
                .font(.headline)
            Spacer()
            Text("Step \(model.step + 1) of 3")
                .foregroundStyle(.secondary)
            ProgressView(value: Double(model.step + 1), total: 3)
                .frame(width: 120)
        }
        .padding(20)
    }

    private var footer: some View {
        HStack {
            if model.step > 0 {
                Button("Back") {
                    model.step -= 1
                }
            }

            if let message = model.statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if model.step < 2 {
                Button("Continue") {
                    model.statusMessage = nil
                    model.step += 1
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Finish") {
                    model.complete()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.draft.whitelistedDomains.isEmpty)
                .help("Choose at least one allowed domain before finishing.")
            }
        }
        .padding(20)
    }
}

