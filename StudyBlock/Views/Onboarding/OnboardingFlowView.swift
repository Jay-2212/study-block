import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Group {
                switch model.step {
                case .permissionPriming:
                    PermissionPrimingStepView(model: model)
                case .studyDomains:
                    StudyDomainsStepView(model: model)
                case .whitelist:
                    WhitelistStepView(model: model)
                case .blacklist:
                    BlacklistStepView(model: model)
                }
            }
            .frame(maxWidth: 620)
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
            OnboardingStepIndicator(currentStep: model.step)
        }
        .padding(20)
    }

    private var footer: some View {
        HStack {
            if model.step.previous != nil {
                Button("Back") {
                    model.goBack()
                }
                .controlSize(.large)
            }

            if let message = model.statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if model.step.next != nil {
                Button("Continue") {
                    model.advance()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Finish") {
                    model.complete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(model.draft.whitelistedDomains.isEmpty)
                .help("Choose at least one allowed domain before finishing.")
            }
        }
        .padding(20)
    }
}

