import AppKit
import Foundation

@MainActor
final class MusicBlockingService {
    private let targets = [
        "com.apple.Music": "Music",
        "com.spotify.client": "Spotify"
    ]
    private var blockedTargets: [String: String] = [:]
    private var timer: Timer?

    func start(allowedBundleIdentifiers: Set<String>) {
        stop()
        blockedTargets = targets.filter {
            !allowedBundleIdentifiers.contains($0.key)
        }
        guard !blockedTargets.isEmpty else { return }
        pauseNow()

        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pauseNow() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        blockedTargets.removeAll()
    }

    private func pauseNow() {
        for (bundleIdentifier, applicationName) in blockedTargets {
            guard NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            ).contains(where: { !$0.isTerminated }) else {
                continue
            }
            let source = """
            tell application "\(applicationName)"
                if player state is playing then pause
            end tell
            """
            var errorInfo: NSDictionary?
            _ = NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)
        }
    }
}
