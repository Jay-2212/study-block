import Foundation
import Observation

@MainActor
@Observable
final class SessionHistoryStore {
    private(set) var sessions: [StudySessionRecord] = []
    private(set) var errorMessage: String?

    private let fileURL: URL
    private let ioQueue = DispatchQueue(
        label: "com.jay.studyblock.sessions",
        qos: .utility
    )

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        load()
    }

    func record(_ session: StudySessionRecord) {
        sessions.append(session)
        sessions.sort { $0.startDate > $1.startDate }
        persist()
    }

    func stats(
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> SessionStats {
        let today = calendar.startOfDay(for: now)
        let weekStart = calendar.dateInterval(
            of: .weekOfYear,
            for: now
        )?.start ?? today

        let todaySeconds = sessions
            .filter { $0.startDate >= today && $0.startDate <= now }
            .reduce(0) { $0 + $1.durationSeconds }
        let weekSeconds = sessions
            .filter { $0.startDate >= weekStart && $0.startDate <= now }
            .reduce(0) { $0 + $1.durationSeconds }

        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startDate) })
        var cursor = activeDays.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)!
        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(
                byAdding: .day,
                value: -1,
                to: cursor
            ) else {
                break
            }
            cursor = previous
        }

        return SessionStats(
            todaySeconds: todaySeconds,
            weekSeconds: weekSeconds,
            streakDays: streak
        )
    }

    private func load() {
        do {
            let loaded: [StudySessionRecord] = try ioQueue.sync {
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    return [StudySessionRecord]()
                }
                return try JSONDecoder().decode(
                    [StudySessionRecord].self,
                    from: Data(contentsOf: fileURL)
                )
            }
            sessions = loaded.sorted { $0.startDate > $1.startDate }
        } catch {
            sessions = []
            errorMessage = "Session history was unreadable and has been reset."
        }
    }

    private func persist() {
        do {
            let snapshot = sessions
            try ioQueue.sync {
                let directory = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
            }
            errorMessage = nil
        } catch {
            errorMessage = "Could not save session history: \(error.localizedDescription)"
        }
    }

    private static var defaultFileURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base
            .appendingPathComponent("Study Block", isDirectory: true)
            .appendingPathComponent("sessions.json")
    }
}
