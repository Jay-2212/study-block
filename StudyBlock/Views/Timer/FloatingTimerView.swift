import SwiftUI

struct FloatingTimerView: View {
    @Bindable var timer: TimerCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timer.isOpenEnded ? "elapsed" : "remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            BigNumberDisplay(value: timer.formattedTime, size: .compact)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .studySurface()
        .padding(4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus timer")
        .accessibilityValue(
            "\(timer.formattedTime) \(timer.isOpenEnded ? "elapsed" : "remaining")"
        )
    }
}
