import XCTest
@testable import StudyBlock

@MainActor
final class SessionHistoryStoreTests: XCTestCase {
    func testStatsAggregateTodayWeekAndStreak() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_753_200_000)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("sessions.json")
        let store = SessionHistoryStore(fileURL: fileURL)

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
                    strictModeEnabled: dayOffset == 0
                )
            )
        }

        let stats = store.stats(now: now, calendar: calendar)
        XCTAssertEqual(stats.todaySeconds, 3_600)
        XCTAssertGreaterThanOrEqual(stats.weekSeconds, 3_600)
        XCTAssertEqual(stats.streakDays, 3)
        try? FileManager.default.removeItem(at: directory)
    }

    func testMissingHistoryStartsEmpty() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("sessions.json")
        let store = SessionHistoryStore(fileURL: fileURL)

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertEqual(store.stats(), .empty)
    }
}
