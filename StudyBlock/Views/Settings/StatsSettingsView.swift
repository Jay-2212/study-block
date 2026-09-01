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

                DailyFocusChartView(points: stats.dailyFocus)

                HStack(alignment: .top, spacing: 12) {
                    BlockedRankList(
                        title: "Most blocked sites",
                        systemImage: "globe",
                        sites: stats.topSites,
                        apps: []
                    )
                    BlockedRankList(
                        title: "Most blocked apps",
                        systemImage: "app.dashed",
                        sites: [],
                        apps: stats.topApps
                    )
                }

                Text("Recent completed sessions")
                    .font(.headline)

                if appModel.sessionHistory.sessions.isEmpty {
                    StudyEmptyState(
                        title: "No completed sessions yet",
                        systemImage: "timer",
                        description: "Finish a timed session or stop an open-ended session to begin your history."
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
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
                VStack(alignment: .leading, spacing: 8) {
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

                    if !session.blockedSites.isEmpty || !session.blockedApps.isEmpty {
                        sessionBlockChips(session)
                    }
                }
                .padding(.vertical, 10)
                if session.id != appModel.sessionHistory.sessions
                    .prefix(12).last?.id {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 14)
        .studySurface(cornerRadius: 12)
    }

    private func sessionBlockChips(_ session: StudySessionRecord) -> some View {
        HStack(spacing: 8) {
            ForEach(session.blockedApps.prefix(4)) { app in
                chip(
                    title: app.name,
                    icon: .application(app.bundleIdentifier)
                )
            }
            ForEach(session.blockedSites.prefix(4)) { site in
                chip(
                    title: site.domain,
                    icon: .website(site.domain)
                )
            }
        }
        .padding(.leading, 34)
    }

    private func chip(title: String, icon: ListIconSource) -> some View {
        HStack(spacing: 5) {
            ListIconView(source: icon, size: 14)
            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.5), in: Capsule())
        .help(title)
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
        .studySurface(cornerRadius: 12)
    }
}
