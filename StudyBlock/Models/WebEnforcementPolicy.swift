import Foundation

enum WebPolicyDecision: Equatable {
    case allowed
    case blocked(domain: String)
    case ignored
}

struct WebEnforcementPolicy: Equatable {
    let blacklistedDomains: Set<String>

    init(blacklistedDomains: [String]) {
        self.blacklistedDomains = Set(blacklistedDomains.map { $0.lowercased() })
    }

    func decision(for urlString: String) -> WebPolicyDecision {
        guard let domain = try? DomainNormalizer.normalize(urlString) else {
            return .ignored
        }
        return blacklistedDomains.contains(domain)
            ? .blocked(domain: domain)
            : .allowed
    }
}
