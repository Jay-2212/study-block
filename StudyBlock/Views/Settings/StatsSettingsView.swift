import SwiftUI

struct StatsSettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        let stats = appModel.sessionHistory.stats()
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    StatCard(
                        title: "Today",
                        value: format(stats.todaySeconds),
                        systemImage: "sun.max"
                    )
                    StatCard(
                        title: "This week",
                        value: format(stats.weekSeconds),
                        systemImage: "calendar"
                    )
                    StatCard(
                        title: "Streak",
                        value: "\(stats.streakDays) day\(stats.streakDays == 1 ? "" : "s")",
                        systemImage: "flame"
                    )
                }

                Text("Recent completed sessions")
                    .font(.headline)

                if appModel.sessionHistory.sessions.isEmpty {
                    ContentUnavailableView(
                        "No completed sessions yet",
                        systemImage: "timer",
                        description: Text(
                            "Finish a timed session or stop an open-ended session to begin your history."
                        )
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    recentSessions
                }

                if let error = appModel.sessionHistory.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            .padding(8)
        }
    }

    private var recentSessions: some View {
        VStack(spacing: 0) {
            ForEach(appModel.sessionHistory.sessions.prefix(12)) { session in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionTitle(session))
                            .font(.body.weight(.medium))
                        Text(
                            session.startDate.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if session.strictModeEnabled {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .help("Strict mode")
                    }
                    Text(format(session.durationSeconds))
                        .monospacedDigit()
                }
                .padding(.vertical, 10)
                if session.id != appModel.sessionHistory.sessions
                    .prefix(12).last?.id {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func sessionTitle(_ session: StudySessionRecord) -> String {
        session.plannedDurationMinutes.map { "\($0)-minute session" }
            ?? "Open-ended session"
    }

    private func format(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 {
            return remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
