import AppKit
import Foundation

enum ChromeDiscoveryError: LocalizedError {
    case chromeNotRunning
    case automationFailed(String)
    case noUsableTabs

    var errorDescription: String? {
        switch self {
        case .chromeNotRunning:
            "Google Chrome is not open. You can paste sites manually."
        case .automationFailed(let message):
            "Chrome tabs could not be read. \(message)"
        case .noUsableTabs:
            "No standard website tabs were found in Chrome."
        }
    }
}

struct ChromeTabDiscoveryService {
    func discoverDomains(
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try Self.discoverDomainsSynchronously() }
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private static func discoverDomainsSynchronously() throws -> [String] {
        let chromeRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.google.Chrome"
        }
        guard chromeRunning else { throw ChromeDiscoveryError.chromeNotRunning }

        let source = """
        tell application "Google Chrome"
            set tabURLs to {}
            repeat with browserWindow in windows
                repeat with browserTab in tabs of browserWindow
                    set end of tabURLs to URL of browserTab
                end repeat
            end repeat
            return tabURLs
        end tell
        """

        var errorInfo: NSDictionary?
        guard let result = NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)
        else {
            let message = errorInfo?[NSAppleScript.errorMessage] as? String
                ?? "Allow Study Block to automate Chrome in System Settings."
            throw ChromeDiscoveryError.automationFailed(message)
        }

        guard result.numberOfItems > 0 else {
            throw ChromeDiscoveryError.noUsableTabs
        }

        let domains = (1...result.numberOfItems)
            .compactMap { result.atIndex($0)?.stringValue }
            .compactMap { try? DomainNormalizer.normalize($0) }

        let unique = Array(Set(domains)).sorted()
        guard !unique.isEmpty else { throw ChromeDiscoveryError.noUsableTabs }
        return unique
    }
}
