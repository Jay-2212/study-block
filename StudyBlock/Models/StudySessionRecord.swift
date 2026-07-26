import Foundation

struct StudySessionRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let durationSeconds: Int
    let plannedDurationMinutes: Int?
    let preset: SessionPreset
    let strictModeEnabled: Bool

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        plannedDurationMinutes: Int?,
        preset: SessionPreset,
        strictModeEnabled: Bool
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        durationSeconds = max(0, Int(endDate.timeIntervalSince(startDate)))
        self.plannedDurationMinutes = plannedDurationMinutes
        self.preset = preset
        self.strictModeEnabled = strictModeEnabled
    }
}

struct SessionStats: Equatable {
    let todaySeconds: Int
    let weekSeconds: Int
    let streakDays: Int

    static let empty = SessionStats(
        todaySeconds: 0,
        weekSeconds: 0,
        streakDays: 0
    )
}
