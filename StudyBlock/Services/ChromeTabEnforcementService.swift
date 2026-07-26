import AppKit
import Foundation

@MainActor
final class ChromeTabEnforcementService: WebEnforcementProvider {
    var redirectHandler: ((String) -> Void)?
    var errorHandler: ((String) -> Void)?

    private let worker = Worker()

    func start(
        policy: WebEnforcementPolicy,
        sessionStartDate: Date,
        sessionEndDate: Date?
    ) {
        worker.start(
            policy: policy,
            sessionStartDate: sessionStartDate,
            sessionEndDate: sessionEndDate,
            onRedirect: { [weak self] domain in
                self?.redirectHandler?(domain)
            },
            onStatus: { [weak self] message in
                self?.errorHandler?(message)
            }
        )
    }

    func stop() {
        worker.stopAndRestore()
    }
}

private extension ChromeTabEnforcementService {
    final class Worker: @unchecked Sendable {
        private struct ChromeTab {
            let windowIndex: Int
            let tabIndex: Int
            let url: String
        }

        private struct RedirectedTab {
            let windowIndex: Int
            let tabIndex: Int
            let originalURL: String
        }

        private let queue = DispatchQueue(
            label: "com.jay.studyblock.chrome",
            qos: .utility
        )
        private let blockPage = BlockPageService()
        private var workItem: DispatchWorkItem?
        private var generation = UUID()
        private var policy = WebEnforcementPolicy(blacklistedDomains: [])
        private var sessionStartDate = Date()
        private var sessionEndDate: Date?
        private var redirectedTabs: [String: RedirectedTab] = [:]
        private var reportedChromeUnavailable = false
        private var onRedirect: ((String) -> Void)?
        private var onStatus: ((String) -> Void)?

        func start(
            policy: WebEnforcementPolicy,
            sessionStartDate: Date,
            sessionEndDate: Date?,
            onRedirect: @escaping (String) -> Void,
            onStatus: @escaping (String) -> Void
        ) {
            stopAndRestore()
            queue.sync {
                generation = UUID()
                self.policy = policy
                self.sessionStartDate = sessionStartDate
                self.sessionEndDate = sessionEndDate
                self.onRedirect = onRedirect
                self.onStatus = onStatus
                reportedChromeUnavailable = false
                do {
                    try blockPage.prepare()
                    schedule(after: 0, generation: generation)
                } catch {
                    publishStatus("The local block page could not be prepared.")
                }
            }
        }

        func stopAndRestore() {
            queue.sync {
                generation = UUID()
                workItem?.cancel()
                workItem = nil
                restoreRedirectedTabs()
                redirectedTabs.removeAll()
                onRedirect = nil
                onStatus = nil
            }
        }

        private func schedule(after delay: TimeInterval, generation: UUID) {
            let item = DispatchWorkItem { [weak self] in
                self?.poll(generation: generation)
            }
            workItem = item
            queue.asyncAfter(deadline: .now() + delay, execute: item)
        }

        private func poll(generation: UUID) {
            guard generation == self.generation else { return }
            guard chromeIsRunning else {
                if !reportedChromeUnavailable {
                    reportedChromeUnavailable = true
                    publishStatus(
                        "Chrome is not running. Website blocking will resume when it opens."
                    )
                }
                schedule(after: 10, generation: generation)
                return
            }

            reportedChromeUnavailable = false
            do {
                let blockedTabs = try readTabs().compactMap {
                    tab -> (ChromeTab, String)? in
                    guard case .blocked(let domain) = policy.decision(for: tab.url)
                    else {
                        return nil
                    }
                    return (tab, domain)
                }
                if !blockedTabs.isEmpty {
                    try redirect(blockedTabs)
                    for (tab, domain) in blockedTabs {
                        let key = "\(tab.windowIndex):\(tab.tabIndex)"
                        if redirectedTabs[key] == nil {
                            redirectedTabs[key] = RedirectedTab(
                                windowIndex: tab.windowIndex,
                                tabIndex: tab.tabIndex,
                                originalURL: tab.url
                            )
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.onRedirect?(domain)
                        }
                    }
                }
            } catch {
                publishStatus(error.localizedDescription)
            }
            schedule(after: 2, generation: generation)
        }

        private var chromeIsRunning: Bool {
            NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.google.Chrome"
            ).contains { !$0.isTerminated }
        }

        private func readTabs() throws -> [ChromeTab] {
            let result = try execute("""
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
            """)
            guard result.numberOfItems > 0 else { return [] }

            return (1...result.numberOfItems).compactMap { index in
                guard let record = result.atIndex(index)?.stringValue else {
                    return nil
                }
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
                    returnURL: tab.url,
                    sessionStartDate: sessionStartDate,
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

        private func restoreRedirectedTabs() {
            guard chromeIsRunning else { return }
            let blockPrefix = blockPage.baseURL.absoluteString
            var tabsToRestore = redirectedTabs.values.map {
                ($0.windowIndex, $0.tabIndex, $0.originalURL)
            }
            if let openTabs = try? readTabs() {
                for tab in openTabs where tab.url.hasPrefix(blockPrefix) {
                    guard let components = URLComponents(string: tab.url),
                          let returnURL = components.queryItems?.first(
                            where: { $0.name == "return" }
                          )?.value else {
                        continue
                    }
                    tabsToRestore.append(
                        (tab.windowIndex, tab.tabIndex, returnURL)
                    )
                }
            }
            let uniqueTabs = Dictionary(
                tabsToRestore.map { ("\($0.0):\($0.1)", $0) },
                uniquingKeysWith: { first, _ in first }
            ).values
            let commands = uniqueTabs.map { windowIndex, tabIndex, originalURL in
                """
                if (count of windows) ≥ \(windowIndex) then
                    if (count of tabs of window \(windowIndex)) ≥ \(tabIndex) then
                        if URL of tab \(tabIndex) of window \(windowIndex) starts with "\(escape(blockPrefix))" then
                            set URL of tab \(tabIndex) of window \(windowIndex) to "\(escape(originalURL))"
                        end if
                    end if
                end if
                """
            }.joined(separator: "\n")
            guard !commands.isEmpty else { return }
            _ = try? execute("""
            tell application "Google Chrome"
            \(commands)
            end tell
            """)
        }

        private func execute(_ source: String) throws -> NSAppleEventDescriptor {
            var errorInfo: NSDictionary?
            guard let result = NSAppleScript(source: source)?
                .executeAndReturnError(&errorInfo) else {
                let message = errorInfo?[NSAppleScript.errorMessage] as? String
                    ?? "Allow Study Block to automate Chrome in System Settings."
                throw ChromeDiscoveryError.automationFailed(message)
            }
            return result
        }

        private func publishStatus(_ message: String) {
            DispatchQueue.main.async { [weak self] in
                self?.onStatus?(message)
            }
        }

        private func escape(_ value: String) -> String {
            value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
        }
    }
}
