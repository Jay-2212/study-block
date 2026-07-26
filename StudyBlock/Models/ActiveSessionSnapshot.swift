import Foundation

struct ActiveSessionSnapshot: Codable, Equatable {
    let startDate: Date
    let endDate: Date?
    let preset: SessionPreset
    let plannedDurationMinutes: Int?
}
