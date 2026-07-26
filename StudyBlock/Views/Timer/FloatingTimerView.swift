import SwiftUI

struct FloatingTimerView: View {
    @Bindable var timer: TimerCoordinator

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("Focus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(timer.formattedRemaining)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .studySurface(cornerRadius: 16)
        .padding(5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus timer")
        .accessibilityValue(timer.formattedRemaining)
    }
}

