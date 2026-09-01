import Foundation

struct BlockedSiteStat: Codable, Equatable, Identifiable, Hashable {
    var domain: String
    var count: Int

    var id: String { domain }
}

struct BlockedAppStat: Codable, Equatable, Identifiable, Hashable {
    var name: String
    var bundleIdentifier: String
    var count: Int

    var id: String { bundleIdentifier }
}

struct DailyFocusPoint: Identifiable, Equatable {
    let date: Date
    let seconds: Int

    var id: Date { date }
}

struct StudySessionRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let durationSeconds: Int
    let plannedDurationMinutes: Int?
    let preset: SessionPreset
    let strictModeEnabled: Bool
    let blockedSites: [BlockedSiteStat]
    let blockedApps: [BlockedAppStat]

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        plannedDurationMinutes: Int?,
        preset: SessionPreset,
        strictModeEnabled: Bool,
        blockedSites: [BlockedSiteStat] = [],
        blockedApps: [BlockedAppStat] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        durationSeconds = max(0, Int(endDate.timeIntervalSince(startDate)))
        self.plannedDurationMinutes = plannedDurationMinutes
        self.preset = preset
        self.strictModeEnabled = strictModeEnabled
        self.blockedSites = blockedSites
        self.blockedApps = blockedApps
    }

    enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case durationSeconds
        case plannedDurationMinutes
        case preset
        case strictModeEnabled
        case blockedSites
        case blockedApps
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        startDate = try values.decode(Date.self, forKey: .startDate)
        endDate = try values.decode(Date.self, forKey: .endDate)
        durationSeconds = try values.decodeIfPresent(
            Int.self,
            forKey: .durationSeconds
        ) ?? max(0, Int(endDate.timeIntervalSince(startDate)))
        plannedDurationMinutes = try values.decodeIfPresent(
            Int.self,
            forKey: .plannedDurationMinutes
        )
        preset = try values.decode(SessionPreset.self, forKey: .preset)
        strictModeEnabled = try values.decode(
            Bool.self,
            forKey: .strictModeEnabled
        )
        blockedSites = try values.decodeIfPresent(
            [BlockedSiteStat].self,
            forKey: .blockedSites
        ) ?? []
        blockedApps = try values.decodeIfPresent(
            [BlockedAppStat].self,
            forKey: .blockedApps
        ) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(startDate, forKey: .startDate)
        try values.encode(endDate, forKey: .endDate)
        try values.encode(durationSeconds, forKey: .durationSeconds)
        try values.encodeIfPresent(
            plannedDurationMinutes,
            forKey: .plannedDurationMinutes
        )
        try values.encode(preset, forKey: .preset)
        try values.encode(strictModeEnabled, forKey: .strictModeEnabled)
        try values.encode(blockedSites, forKey: .blockedSites)
        try values.encode(blockedApps, forKey: .blockedApps)
    }
}

struct SessionStats: Equatable {
    let todaySeconds: Int
    let weekSeconds: Int
    let streakDays: Int
    let dailyFocus: [DailyFocusPoint]
    let topSites: [BlockedSiteStat]
    let topApps: [BlockedAppStat]

    static let empty = SessionStats(
        todaySeconds: 0,
        weekSeconds: 0,
        streakDays: 0,
        dailyFocus: [],
        topSites: [],
        topApps: []
    )
}
