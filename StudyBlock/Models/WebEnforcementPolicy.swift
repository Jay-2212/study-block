import Foundation

enum WebPolicyDecision: Equatable {
    case allowed
    case blocked(domain: String)
    case ignored
}

struct WebEnforcementPolicy: Equatable {
    private static let permanentlyAllowedDomains: Set<String> = [
        "anthropic.com",
        "chatgpt.com",
        "claude.ai",
        "google.ca",
        "google.co.in",
        "google.co.jp",
        "google.co.uk",
        "google.com",
        "google.com.au",
        "google.de",
        "google.fr",
        "openai.com"
    ]

    let blacklistedDomains: Set<String>

    init(blacklistedDomains: [String]) {
        self.blacklistedDomains = Set(blacklistedDomains.map { $0.lowercased() })
    }

    func decision(for urlString: String) -> WebPolicyDecision {
        guard let domain = try? DomainNormalizer.normalize(urlString) else {
            return .ignored
        }
        if Self.isPermanentlyAllowed(domain) {
            return .allowed
        }
        return blacklistedDomains.contains(domain)
            ? .blocked(domain: domain)
            : .allowed
    }

    static func isPermanentlyAllowed(_ domain: String) -> Bool {
        permanentlyAllowedDomains.contains(domain.lowercased())
    }
}
