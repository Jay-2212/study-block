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

    func testWorkSitesAreBlockedWhenListed() {
        let policy = WebEnforcementPolicy(
            blacklistedDomains: [
                "google.com", "chatgpt.com", "claude.ai"
            ]
        )
        XCTAssertEqual(
            policy.decision(for: "https://docs.google.com/document/1"),
            .blocked(domain: "google.com")
        )
        XCTAssertEqual(
            policy.decision(for: "https://chatgpt.com"),
            .blocked(domain: "chatgpt.com")
        )
        XCTAssertEqual(
            policy.decision(for: "https://claude.ai"),
            .blocked(domain: "claude.ai")
        )
    }

    func testUnlistedWorkSitesStayAllowed() {
        let policy = WebEnforcementPolicy(blacklistedDomains: ["youtube.com"])
        XCTAssertEqual(policy.decision(for: "https://chatgpt.com"), .allowed)
        XCTAssertEqual(policy.decision(for: "https://claude.ai"), .allowed)
    }
}
