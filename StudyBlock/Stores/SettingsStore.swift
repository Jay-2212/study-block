import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    private(set) var settings: AppSettings
    private(set) var errorMessage: String?
    /// A one-shot counterpart to `errorMessage` for alert presentation.
    /// `errorMessage` persists as a passive supplement (shown inline in
    /// Settings) until the next successful save; this instead clears the
    /// moment the user acknowledges the alert, and re-arms on every new
    /// failure even if the message text repeats.
    private(set) var pendingErrorAlert: String?
    var changeHandler: ((AppSettings) -> Void)?

    private let fileURL: URL
    private let ioQueue = DispatchQueue(
        label: "com.jay.studyblock.settings",
        qos: .utility
    )

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        settings = .empty
        load()
    }

    func save(_ newSettings: AppSettings) {
        let sanitized = Self.sanitize(newSettings)
        do {
            try ioQueue.sync {
                let directory = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                try encoder.encode(sanitized).write(to: fileURL, options: .atomic)
            }
            settings = sanitized
            errorMessage = nil
            pendingErrorAlert = nil
            changeHandler?(sanitized)
        } catch {
            let message = "Could not save settings: \(error.localizedDescription)"
            errorMessage = message
            pendingErrorAlert = message
        }
    }

    func acknowledgeErrorAlert() {
        pendingErrorAlert = nil
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

    func updateLaunchAtLogin(_ isEnabled: Bool) {
        var updated = settings
        updated.launchAtLoginEnabled = isEnabled
        save(updated)
    }

    func updateShowFloatingTimer(_ isEnabled: Bool) {
        var updated = settings
        updated.showFloatingTimer = isEnabled
        save(updated)
    }

    func updateShowNotchIndicator(_ isEnabled: Bool) {
        var updated = settings
        updated.showNotchIndicator = isEnabled
        save(updated)
    }

    private func load() {
        do {
            let loaded: AppSettings? = try ioQueue.sync {
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    return nil
                }
                return try JSONDecoder().decode(
                    AppSettings.self,
                    from: Data(contentsOf: fileURL)
                )
            }
            settings = Self.sanitize(loaded ?? .empty)
        } catch {
            settings = .empty
            let message = "Settings were unreadable, so safe defaults were restored."
            errorMessage = message
            pendingErrorAlert = message
        }
    }

    private static func sanitize(_ candidate: AppSettings) -> AppSettings {
        var settings = candidate
        settings.whitelistedDomains = normalizedUnique(settings.whitelistedDomains)
        let allowed = Set(settings.whitelistedDomains)
        settings.blacklistedDomains = normalizedUnique(settings.blacklistedDomains)
            .filter { !allowed.contains($0) }
        settings.sessionPresetMinutes = Array(
            settings.sessionPresetMinutes.prefix(3)
        ).map { min(max($0, 1), 480) }
        while settings.sessionPresetMinutes.count < 3 {
            settings.sessionPresetMinutes.append(
                defaultPreset(at: settings.sessionPresetMinutes.count)
            )
        }
        return settings
    }

    private static func normalizedUnique(_ domains: [String]) -> [String] {
        Array(Set(domains.compactMap { try? DomainNormalizer.normalize($0) }))
            .sorted()
    }

    private static func defaultPreset(at index: Int) -> Int {
        AppSettings.defaultSessionPresetMinutes[
            min(index, AppSettings.defaultSessionPresetMinutes.count - 1)
        ]
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
