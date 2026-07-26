import XCTest
@testable import StudyBlock

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testSettingsRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("settings.json")

        let store = SettingsStore(fileURL: fileURL)
        var expected = AppSettings.empty
        expected.hasCompletedOnboarding = true
        expected.whitelistedDomains = ["google.com", "notion.so"]
        store.save(expected)

        XCTAssertEqual(SettingsStore(fileURL: fileURL).settings, expected)
        try? FileManager.default.removeItem(at: directory)
    }
}

