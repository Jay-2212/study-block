import Foundation

final class ActiveSessionPersistence: @unchecked Sendable {
    private let fileURL: URL
    private let queue = DispatchQueue(
        label: "com.jay.studyblock.active-session",
        qos: .utility
    )

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
    }

    func load() -> ActiveSessionSnapshot? {
        queue.sync {
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? JSONDecoder().decode(
                ActiveSessionSnapshot.self,
                from: data
            )
        }
    }

    func save(_ snapshot: ActiveSessionSnapshot) {
        queue.sync {
            do {
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                try encoder.encode(snapshot).write(
                    to: fileURL,
                    options: .atomic
                )
            } catch {
                // Session enforcement remains safe in memory if checkpointing fails.
            }
        }
    }

    func clear() {
        queue.sync {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static var defaultFileURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base
            .appendingPathComponent("Study Block", isDirectory: true)
            .appendingPathComponent("active-session.json")
    }
}
