import AppKit
import Foundation

@MainActor
final class MusicBlockingService {
    private let worker = Worker()

    func start(allowedBundleIdentifiers: Set<String>) {
        worker.start(allowedBundleIdentifiers: allowedBundleIdentifiers)
    }

    func stop() {
        worker.stop()
    }
}

private extension MusicBlockingService {
    final class Worker: @unchecked Sendable {
        private let targets = [
            "com.apple.Music": "Music",
            "com.spotify.client": "Spotify"
        ]
        private let queue = DispatchQueue(
            label: "com.jay.studyblock.music",
            qos: .utility
        )
        private var blockedTargets: [String: String] = [:]
        private var workItem: DispatchWorkItem?
        private var generation = UUID()

        func start(allowedBundleIdentifiers: Set<String>) {
            stop()
            queue.sync {
                blockedTargets = targets.filter {
                    !allowedBundleIdentifiers.contains($0.key)
                }
                guard !blockedTargets.isEmpty else { return }
                generation = UUID()
                schedule(after: 0, generation: generation)
            }
        }

        func stop() {
            queue.sync {
                generation = UUID()
                workItem?.cancel()
                workItem = nil
                blockedTargets.removeAll()
            }
        }

        private func schedule(after delay: TimeInterval, generation: UUID) {
            let item = DispatchWorkItem { [weak self] in
                self?.pauseAndReschedule(generation: generation)
            }
            workItem = item
            queue.asyncAfter(deadline: .now() + delay, execute: item)
        }

        private func pauseAndReschedule(generation: UUID) {
            guard generation == self.generation else { return }
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
            schedule(after: 2, generation: generation)
        }
    }
}
