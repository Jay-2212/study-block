import Foundation

@main
struct SettingsStoreSmoke {
    @MainActor
    static func main() {
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

        precondition(
            store.settings.blacklistedDomains == ["google.com", "youtube.com"]
        )
        precondition(store.settings.whitelistedDomains == ["notion.so"])
        precondition(SettingsStore(fileURL: fileURL).settings == store.settings)
        try? FileManager.default.removeItem(at: directory)
        print("Settings persistence smoke checks passed.")
    }
}
