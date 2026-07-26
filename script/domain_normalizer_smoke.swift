import Foundation

@main
enum DomainNormalizerSmoke {
    static func main() throws {
        let cases = [
            ("https://docs.google.com/document/123", "google.com"),
            ("learn.ox.ac.uk/course", "ox.ac.uk"),
            ("WWW.NOTION.SO", "notion.so"),
            ("https://news.ycombinator.com", "ycombinator.com")
        ]

        for (input, expected) in cases {
            let actual = try DomainNormalizer.normalize(input)
            guard actual == expected else {
                fatalError("\(input): expected \(expected), got \(actual)")
            }
        }

        let rejected = ["localhost:3000", "chrome://settings", "127.0.0.1"]
        for input in rejected {
            guard (try? DomainNormalizer.normalize(input)) == nil else {
                fatalError("\(input) should have been rejected")
            }
        }

        print("Domain normalization smoke checks passed.")
    }
}

