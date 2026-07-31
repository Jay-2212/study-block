import SwiftUI

/// The shared countdown/value treatment used by the timer setup screen, the
/// floating timer, and the app nudge. Two sizes only: `.large` for the
/// primary in-window countdown and `.compact` for secondary contexts.
enum BigNumberSize {
    case large
    case compact

    var fontSize: CGFloat {
        switch self {
        case .large: 64
        case .compact: 32
        }
    }
}

struct BigNumberDisplay: View {
    let value: String
    var size: BigNumberSize = .large
    var urgent: Bool = false

    var body: some View {
        Text(value)
            .font(
                .system(
                    size: size.fontSize,
                    weight: urgent ? .bold : .semibold,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .foregroundStyle(urgent ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
