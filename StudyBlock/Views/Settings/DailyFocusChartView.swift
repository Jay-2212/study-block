import Charts
import SwiftUI

struct DailyFocusChartView: View {
    let points: [DailyFocusPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus by day")
                .font(.headline)
            if points.allSatisfy({ $0.seconds == 0 }) {
                StudyEmptyState(
                    title: "No focus time yet",
                    systemImage: "chart.bar",
                    description: "Finish a session and it will land on this 14-day log.",
                    compact: true
                )
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Minutes", Double(point.seconds) / 60)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
                }
                .frame(height: 168)
                .accessibilityLabel("Focus minutes for the last 14 days")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .studySurface(cornerRadius: 12)
    }
}
