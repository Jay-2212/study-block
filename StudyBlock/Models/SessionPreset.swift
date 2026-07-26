import Foundation

enum SessionPreset: String, CaseIterable, Codable, Identifiable {
    case sixty
    case ninety
    case oneTwenty
    case openEnded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sixty: "60 min"
        case .ninety: "90 min"
        case .oneTwenty: "120 min"
        case .openEnded: "Open-ended"
        }
    }

    var durationMinutes: Int? {
        switch self {
        case .sixty: 60
        case .ninety: 90
        case .oneTwenty: 120
        case .openEnded: nil
        }
    }
}
