import Foundation

struct SitePreset: Identifiable, Hashable {
    let name: String
    let domain: String
    let systemImage: String

    var id: String { domain }
}

extension SitePreset {
    static let productive: [SitePreset] = [
        SitePreset(name: "Google", domain: "google.com", systemImage: "magnifyingglass"),
        SitePreset(name: "ChatGPT", domain: "chatgpt.com", systemImage: "sparkles"),
        SitePreset(name: "Claude", domain: "claude.ai", systemImage: "brain"),
        SitePreset(name: "Notion", domain: "notion.so", systemImage: "doc.text"),
        SitePreset(name: "GitHub", domain: "github.com", systemImage: "chevron.left.forwardslash.chevron.right"),
        SitePreset(name: "Stack Overflow", domain: "stackoverflow.com", systemImage: "questionmark.bubble")
    ]

    static let distracting: [SitePreset] = [
        SitePreset(name: "YouTube", domain: "youtube.com", systemImage: "play.rectangle"),
        SitePreset(name: "Reddit", domain: "reddit.com", systemImage: "bubble.left.and.bubble.right"),
        SitePreset(name: "X", domain: "x.com", systemImage: "text.bubble"),
        SitePreset(name: "Instagram", domain: "instagram.com", systemImage: "camera"),
        SitePreset(name: "Facebook", domain: "facebook.com", systemImage: "person.2"),
        SitePreset(name: "Twitch", domain: "twitch.tv", systemImage: "tv")
    ]
}

