import SwiftUI

struct NotchOutlineView: View {
    @Bindable var timer: TimerCoordinator
    var hasNotch: Bool

    var body: some View {
        if hasNotch {
            notchContour
        } else {
            compactPill
        }
    }

    private var notchContour: some View {
        ZStack {
            // Background track
            NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
                .stroke(Color.white.opacity(0.15), lineWidth: 2)

            // Progress stroke
            if timer.isOpenEnded {
                NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
                    .stroke(
                        Color.accentColor.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 3)
            } else {
                NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
                    .trim(from: 0, to: max(0.01, min(1.0, timer.progress)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .shadow(color: Color.accentColor.opacity(0.6), radius: 4)
                    .animation(.easeInOut(duration: 0.3), value: timer.progress)
            }
        }
        .frame(width: 214, height: 35)
        .padding(.top, 0)
    }

    private var compactPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
            Text(timer.formattedTime)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
        }
        .overlay {
            if !timer.isOpenEnded {
                Capsule()
                    .trim(from: 0, to: max(0.01, min(1.0, timer.progress)))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .animation(.easeInOut(duration: 0.3), value: timer.progress)
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}
