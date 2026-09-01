import Foundation

@main
enum EnforcementPolicySmoke {
    static func main() {
        let policy = WebEnforcementPolicy(
            blacklistedDomains: [
                "youtube.com", "google.com", "chatgpt.com", "claude.ai"
            ]
        )
        guard policy.decision(for: "https://youtube.com/watch?v=1")
                == .blocked(domain: "youtube.com") else {
            fatalError("YouTube should be blocked")
        }
        for blocked in [
            "https://docs.google.com",
            "https://chatgpt.com",
            "https://claude.ai"
        ] {
            guard case .blocked = policy.decision(for: blocked) else {
                fatalError("\(blocked) should be blocked when listed")
            }
        }
        let openPolicy = WebEnforcementPolicy(blacklistedDomains: ["youtube.com"])
        guard openPolicy.decision(for: "https://chatgpt.com") == .allowed else {
            fatalError("Unlisted work sites should stay allowed")
        }
        print("Web enforcement policy smoke checks passed.")
    }
}
