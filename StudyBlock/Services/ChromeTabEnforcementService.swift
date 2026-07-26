import AppKit
import Foundation

@MainActor
final class ChromeTabEnforcementService: WebEnforcementProvider {
    var redirectHandler: ((String) -> Void)?
    var errorHandler: ((String) -> Void)?

    private struct ChromeTab {
        let windowIndex: Int
        let tabIndex: Int
        let url: String
    }

    private let blockPage = BlockPageService()
    private var policy = WebEnforcementPolicy(blacklistedDomains: [])
    private var sessionEndDate = Date()
    private var pollTimer: Timer?

    func start(policy: WebEnforcementPolicy, sessionEndDate: Date) {
        stop()
        self.policy = policy
        self.sessionEndDate = sessionEndDate

        do {
            try blockPage.prepare()
        } catch {
            errorHandler?("The local block page could not be prepared.")
            return
        }

        enforceNow()
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.enforceNow() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func enforceNow() {
        guard chromeIsRunning else { return }

        do {
            let blockedTabs = try readTabs().compactMap { tab -> (ChromeTab, String)? in
                guard case .blocked(let domain) = policy.decision(for: tab.url) else {
                    return nil
                }
                return (tab, domain)
            }
            guard !blockedTabs.isEmpty else { return }
            try redirect(blockedTabs)
            blockedTabs.forEach { redirectHandler?($0.1) }
        } catch {
            errorHandler?(error.localizedDescription)
        }
    }

    private var chromeIsRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.google.Chrome"
        }
    }

    private func readTabs() throws -> [ChromeTab] {
        let source = """
        tell application "Google Chrome"
            set tabRecords to {}
            repeat with windowIndex from 1 to count of windows
                set browserWindow to window windowIndex
                repeat with tabIndex from 1 to count of tabs of browserWindow
                    set tabURL to URL of tab tabIndex of browserWindow
                    set delimiter to ASCII character 9
                    set end of tabRecords to ((windowIndex as text) & delimiter & (tabIndex as text) & delimiter & tabURL)
                end repeat
            end repeat
            return tabRecords
        end tell
        """

        let result = try execute(source)
        guard result.numberOfItems > 0 else { return [] }

        return (1...result.numberOfItems).compactMap { index in
            guard let record = result.atIndex(index)?.stringValue else { return nil }
            let pieces = record.split(
                separator: "\t",
                maxSplits: 2,
                omittingEmptySubsequences: false
            )
            guard pieces.count == 3,
                  let windowIndex = Int(pieces[0]),
                  let tabIndex = Int(pieces[1]) else {
                return nil
            }
            return ChromeTab(
                windowIndex: windowIndex,
                tabIndex: tabIndex,
                url: String(pieces[2])
            )
        }
    }

    private func redirect(_ blockedTabs: [(ChromeTab, String)]) throws {
        let commands = blockedTabs.map { tab, domain in
            let destination = blockPage.url(
                blockedDomain: domain,
                sessionEndDate: sessionEndDate
            ).absoluteString
            return """
            if (count of windows) ≥ \(tab.windowIndex) then
                if (count of tabs of window \(tab.windowIndex)) ≥ \(tab.tabIndex) then
                    set URL of tab \(tab.tabIndex) of window \(tab.windowIndex) to "\(escape(destination))"
                end if
            end if
            """
        }.joined(separator: "\n")

        _ = try execute("""
        tell application "Google Chrome"
        \(commands)
        end tell
        """)
    }

    private func execute(_ source: String) throws -> NSAppleEventDescriptor {
        var errorInfo: NSDictionary?
        guard let result = NSAppleScript(source: source)?.executeAndReturnError(&errorInfo) else {
            let message = errorInfo?[NSAppleScript.errorMessage] as? String
                ?? "Allow Study Block to automate Chrome in System Settings."
            throw ChromeDiscoveryError.automationFailed(message)
        }
        return result
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
