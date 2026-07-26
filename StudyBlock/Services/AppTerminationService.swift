import AppKit

@MainActor
struct AppTerminationService {
    static let studyBlockBundleIdentifier = "com.jay.studyblock"

    func isRunning(bundleIdentifier: String) -> Bool {
        NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).contains { !$0.isTerminated }
    }

    func requestQuit(
        bundleIdentifier: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard bundleIdentifier != Self.studyBlockBundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier else {
            completion(false)
            return
        }

        let applications = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).filter { !$0.isTerminated }
        guard !applications.isEmpty else {
            completion(true)
            return
        }

        let accepted = applications.allSatisfy { $0.terminate() }
        guard accepted else {
            completion(false)
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            completion(
                NSRunningApplication.runningApplications(
                    withBundleIdentifier: bundleIdentifier
                ).allSatisfy(\.isTerminated)
            )
        }
    }
}
