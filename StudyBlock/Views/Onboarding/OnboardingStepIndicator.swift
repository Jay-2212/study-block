import SwiftUI

/// A segmented dot indicator communicating progress through onboarding,
/// replacing a bare "Step X of Y" label with a setup-assistant-style cue.
struct OnboardingStepIndicator: View {
    let currentStep: OnboardingStep

    var body: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases) { step in
                Capsule()
                    .fill(
                        step.rawValue <= currentStep.rawValue
                            ? Color.accentColor
                            : Color.secondary.opacity(0.25)
                    )
                    .frame(
                        width: step == currentStep ? 20 : 6,
                        height: 6
                    )
            }
        }
        .animation(.snappy, value: currentStep)
        .accessibilityElement()
        .accessibilityLabel(
            "Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)"
        )
    }
}
