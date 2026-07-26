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
        for allowed in [
            "https://docs.google.com",
            "https://chatgpt.com",
            "https://claude.ai"
        ] {
            guard policy.decision(for: allowed) == .allowed else {
                fatalError("\(allowed) must always be allowed")
            }
        }
        print("Web enforcement policy smoke checks passed.")
    }
}
