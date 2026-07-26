import XCTest
@testable import StudyBlock

final class ActiveSessionPersistenceTests: XCTestCase {
    func testCheckpointRoundTripAndClear() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("active-session.json")
        let persistence = ActiveSessionPersistence(fileURL: fileURL)
        let snapshot = ActiveSessionSnapshot(
            startDate: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 4_600),
            preset: .sixty,
            plannedDurationMinutes: 60
        )

        persistence.save(snapshot)
        XCTAssertEqual(persistence.load(), snapshot)
        persistence.clear()
        XCTAssertNil(persistence.load())
        try? FileManager.default.removeItem(at: directory)
    }
}
