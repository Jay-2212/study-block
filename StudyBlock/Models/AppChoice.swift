import Foundation

struct AppChoice: Codable, Hashable, Identifiable {
    let name: String
    let bundleIdentifier: String

    var id: String { bundleIdentifier }

    static func == (lhs: AppChoice, rhs: AppChoice) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
}

extension AppChoice {
    static let productivePresets: [AppChoice] = [
        AppChoice(name: "ChatGPT", bundleIdentifier: "com.openai.chat"),
        AppChoice(name: "WhatsApp", bundleIdentifier: "net.whatsapp.WhatsApp"),
        AppChoice(name: "Spotify", bundleIdentifier: "com.spotify.client")
    ]
}
