import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    private(set) var settings: AppSettings
    private(set) var errorMessage: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        settings = .empty
        load()
    }

    func save(_ newSettings: AppSettings) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try encoder.encode(newSettings).write(to: fileURL, options: .atomic)
            settings = newSettings
            errorMessage = nil
        } catch {
            errorMessage = "Could not save settings: \(error.localizedDescription)"
        }
    }

    func resetOnboarding() {
        var updated = settings
        updated.hasCompletedOnboarding = false
        save(updated)
    }

    func updateStrictMode(_ isEnabled: Bool) {
        var updated = settings
        updated.strictModeEnabled = isEnabled
        save(updated)
    }

    func updateDoNotDisturb(_ isEnabled: Bool) {
        var updated = settings
        updated.doNotDisturbEnabled = isEnabled
        save(updated)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            settings = try decoder.decode(
                AppSettings.self,
                from: Data(contentsOf: fileURL)
            )
        } catch {
            errorMessage = "Could not load settings: \(error.localizedDescription)"
        }
    }

    private static var defaultFileURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base
            .appendingPathComponent("Study Block", isDirectory: true)
            .appendingPathComponent("settings.json")
    }
}
