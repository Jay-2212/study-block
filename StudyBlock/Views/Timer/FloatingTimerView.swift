import SwiftUI

struct PerimeterRoundedRectangle: Shape {
    var cornerRadius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.minY + radius),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX, y: rect.maxY - radius),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.minY),
            tangent2End: CGPoint(x: rect.minX + radius, y: rect.minY),
            radius: radius
        )
        path.closeSubpath()
        return path
    }
}

struct FloatingTimerView: View {
    @Bindable var timer: TimerCoordinator

    var body: some View {
        VStack(spacing: 3) {
            Text(timer.isOpenEnded ? "elapsed" : "remaining")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            BigNumberDisplay(value: timer.formattedTime, size: .compact)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
        }
        .overlay {
            PerimeterRoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 3)
        }
        .overlay {
            if timer.isOpenEnded {
                PerimeterRoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.accentColor.opacity(0.4),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
            } else {
                PerimeterRoundedRectangle(cornerRadius: 16)
                    .trim(from: 0, to: max(0.01, min(1.0, timer.progress)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .animation(.easeInOut(duration: 0.25), value: timer.progress)
            }
        }
        .padding(5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus timer")
        .accessibilityValue(
            "\(timer.formattedTime) \(timer.isOpenEnded ? "elapsed" : "remaining")"
        )
    }
}
