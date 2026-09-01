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
        XCTAssertEqual(stats.dailyFocus.count, 14)
        XCTAssertEqual(
            stats.dailyFocus.last?.seconds,
            3_600
        )
        try? FileManager.default.removeItem(at: directory)
    }

    func testMissingHistoryStartsEmpty() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("sessions.json")
        let store = SessionHistoryStore(fileURL: fileURL)

        XCTAssertTrue(store.sessions.isEmpty)
        let stats = store.stats()
        XCTAssertEqual(stats.todaySeconds, 0)
        XCTAssertEqual(stats.weekSeconds, 0)
        XCTAssertEqual(stats.streakDays, 0)
        XCTAssertTrue(stats.topSites.isEmpty)
        XCTAssertTrue(stats.topApps.isEmpty)
    }

    func testLegacySessionsDecodeWithoutBlockStats() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("sessions.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let start = Date(timeIntervalSince1970: 1_753_200_000)
        let end = start.addingTimeInterval(1_800)
        let payload = """
        [{
          "id": "11111111-1111-1111-1111-111111111111",
          "startDate": \(start.timeIntervalSinceReferenceDate),
          "endDate": \(end.timeIntervalSinceReferenceDate),
          "durationSeconds": 1800,
          "plannedDurationMinutes": 30,
          "preset": "sixty",
          "strictModeEnabled": false
        }]
        """
        try Data(payload.utf8).write(to: fileURL)

        let store = SessionHistoryStore(fileURL: fileURL)
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].durationSeconds, 1_800)
        XCTAssertTrue(store.sessions[0].blockedSites.isEmpty)
        XCTAssertTrue(store.sessions[0].blockedApps.isEmpty)
        try? FileManager.default.removeItem(at: directory)
    }

    func testBlockStatsAggregateAcrossSessions() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("sessions.json")
        let store = SessionHistoryStore(fileURL: fileURL)
        let start = Date()
        store.record(
            StudySessionRecord(
                startDate: start,
                endDate: start.addingTimeInterval(600),
                plannedDurationMinutes: 10,
                preset: .sixty,
                strictModeEnabled: false,
                blockedSites: [
                    BlockedSiteStat(domain: "youtube.com", count: 2)
                ],
                blockedApps: [
                    BlockedAppStat(
                        name: "Discord",
                        bundleIdentifier: "com.hnc.Discord",
                        count: 1
                    )
                ]
            )
        )
        store.record(
            StudySessionRecord(
                startDate: start.addingTimeInterval(1_000),
                endDate: start.addingTimeInterval(1_600),
                plannedDurationMinutes: 10,
                preset: .sixty,
                strictModeEnabled: false,
                blockedSites: [
                    BlockedSiteStat(domain: "youtube.com", count: 1),
                    BlockedSiteStat(domain: "reddit.com", count: 4)
                ],
                blockedApps: []
            )
        )

        let stats = store.stats()
        XCTAssertEqual(stats.topSites.first?.domain, "reddit.com")
        XCTAssertEqual(stats.topSites.first?.count, 4)
        XCTAssertEqual(
            stats.topSites.first(where: { $0.domain == "youtube.com" })?.count,
            3
        )
        XCTAssertEqual(stats.topApps.first?.name, "Discord")
        try? FileManager.default.removeItem(at: directory)
    }
}
