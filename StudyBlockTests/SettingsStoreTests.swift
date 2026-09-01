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

    func testLegacySettingsDefaultPhaseThreeOptionsOff() throws {
        let data = Data("""
        {
          "hasCompletedOnboarding": true,
          "whitelistedDomains": [],
          "blacklistedDomains": [],
          "whitelistedApps": [],
          "blacklistedApps": [],
          "sessionDurationMinutes": 25
        }
        """.utf8)

        let settings = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertFalse(settings.strictModeEnabled)
        XCTAssertFalse(settings.doNotDisturbEnabled)
        XCTAssertEqual(
            settings.sessionPresetMinutes,
            AppSettings.defaultSessionPresetMinutes
        )
        XCTAssertFalse(settings.launchAtLoginEnabled)
    }

    func testAllowlistWinsAndWorkSitesCanBeBlocked() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("settings.json")
        let store = SettingsStore(fileURL: fileURL)
        var settings = AppSettings.empty
        settings.whitelistedDomains = ["notion.so"]
        settings.blacklistedDomains = [
            "notion.so",
            "google.com",
            "youtube.com"
        ]

        store.save(settings)

        XCTAssertEqual(store.settings.whitelistedDomains, ["notion.so"])
        XCTAssertEqual(
            store.settings.blacklistedDomains,
            ["google.com", "youtube.com"]
        )
        try? FileManager.default.removeItem(at: directory)
    }

    func testCorruptedSettingsRecoverWithDefaults() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("settings.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: fileURL)

        let store = SettingsStore(fileURL: fileURL)

        XCTAssertEqual(store.settings, .empty)
        XCTAssertNotNil(store.errorMessage)
        try? FileManager.default.removeItem(at: directory)
    }
}
