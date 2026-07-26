import XCTest
@testable import StudyBlock

final class WebEnforcementPolicyTests: XCTestCase {
    func testBlacklistBlocksMatchingDomain() {
        let policy = WebEnforcementPolicy(blacklistedDomains: ["youtube.com"])
        XCTAssertEqual(
            policy.decision(for: "https://www.youtube.com/watch?v=123"),
            .blocked(domain: "youtube.com")
        )
    }

    func testPermanentAllowancesOverrideBlacklist() {
        let policy = WebEnforcementPolicy(
            blacklistedDomains: [
                "google.com", "google.co.in", "chatgpt.com",
                "openai.com", "claude.ai", "anthropic.com"
            ]
        )
        let urls = [
            "https://docs.google.com/document/1",
            "https://www.google.co.in/search?q=focus",
            "https://chatgpt.com",
            "https://platform.openai.com",
            "https://claude.ai",
            "https://docs.anthropic.com"
        ]
        for url in urls {
            XCTAssertEqual(policy.decision(for: url), .allowed)
        }
    }
}
