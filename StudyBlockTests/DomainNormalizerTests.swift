import XCTest
@testable import StudyBlock

final class DomainNormalizerTests: XCTestCase {
    func testStripsSubdomainsAndPaths() throws {
        XCTAssertEqual(
            try DomainNormalizer.normalize("https://docs.google.com/document/123"),
            "google.com"
        )
    }

    func testPreservesRegistrableDomainForMultiLabelSuffix() throws {
        XCTAssertEqual(
            try DomainNormalizer.normalize("https://learn.ox.ac.uk/course"),
            "ox.ac.uk"
        )
    }

    func testNormalizesCaseAndTrailingDot() throws {
        XCTAssertEqual(
            try DomainNormalizer.normalize("HTTPS://WWW.NOTION.SO./page"),
            "notion.so"
        )
    }

    func testRejectsLocalAndInternalAddresses() {
        XCTAssertThrowsError(try DomainNormalizer.normalize("localhost:3000"))
        XCTAssertThrowsError(try DomainNormalizer.normalize("chrome://settings"))
        XCTAssertThrowsError(try DomainNormalizer.normalize("127.0.0.1"))
    }
}

