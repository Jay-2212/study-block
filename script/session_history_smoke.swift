import Foundation

@main
struct SessionHistorySmoke {
    @MainActor
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_753_200_000)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = SessionHistoryStore(
            fileURL: directory.appendingPathComponent("sessions.json")
        )
        for dayOffset in 0...2 {
            let start = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: now
            )!
            store.record(
                StudySessionRecord(
                    startDate: start,
                    endDate: start.addingTimeInterval(3_600),
                    plannedDurationMinutes: 60,
                    preset: .sixty,
                    strictModeEnabled: false
                )
            )
        }

        let stats = store.stats(now: now, calendar: calendar)
        precondition(stats.todaySeconds == 3_600)
        precondition(stats.streakDays == 3)
        precondition(stats.dailyFocus.count == 14)
        precondition(stats.topSites.isEmpty)
        precondition(SessionHistoryStore(
            fileURL: directory.appendingPathComponent("sessions.json")
        ).sessions.count == 3)
        try? FileManager.default.removeItem(at: directory)
        print("Session history smoke checks passed.")
    }
}
