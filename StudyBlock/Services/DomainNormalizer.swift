import Foundation

enum DomainNormalizationError: LocalizedError {
    case empty
    case unsupported
    case invalidHost

    var errorDescription: String? {
        switch self {
        case .empty:
            "Enter a website or domain."
        case .unsupported:
            "That address cannot be used as a website."
        case .invalidHost:
            "Enter a valid website, such as notion.so."
        }
    }
}

enum DomainNormalizer {
    private static let multiLabelPublicSuffixes: Set<String> = [
        "ac.in", "ac.jp", "ac.nz", "ac.uk",
        "co.in", "co.jp", "co.nz", "co.uk", "co.za",
        "com.au", "com.br", "com.cn", "com.mx", "com.sg", "com.tr",
        "edu.au", "gov.in", "gov.uk", "net.au", "org.au", "org.in", "org.uk"
    ]

    static func normalize(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DomainNormalizationError.empty }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: candidate),
              let rawHost = components.host?.lowercased() else {
            throw DomainNormalizationError.invalidHost
        }

        let host = rawHost.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard host != "localhost",
              !host.hasSuffix(".local"),
              host.range(of: #"^\d{1,3}(\.\d{1,3}){3}$"#, options: .regularExpression) == nil
        else {
            throw DomainNormalizationError.unsupported
        }

        let labels = host.split(separator: ".").map(String.init)
        guard labels.count >= 2,
              labels.allSatisfy(isValidLabel) else {
            throw DomainNormalizationError.invalidHost
        }

        let suffix = labels.suffix(2).joined(separator: ".")
        let count = multiLabelPublicSuffixes.contains(suffix) ? 3 : 2
        guard labels.count >= count else { throw DomainNormalizationError.invalidHost }
        return labels.suffix(count).joined(separator: ".")
    }

    private static func isValidLabel(_ label: String) -> Bool {
        guard !label.isEmpty,
              label.count <= 63,
              label.first != "-",
              label.last != "-" else {
            return false
        }
        return label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}

