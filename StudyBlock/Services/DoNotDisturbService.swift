import ApplicationServices
import AppKit
import Foundation
import Intents
import Observation

@MainActor
@Observable
final class DoNotDisturbService {
    private(set) var statusMessage: String?
    private(set) var isActiveForSession = false
    private(set) var isAccessibilityTrusted = AXIsProcessTrusted()

    @ObservationIgnored private var changedFocus = false
    @ObservationIgnored private var hasSession = false
    @ObservationIgnored private var activationRequested = false
    @ObservationIgnored private var sessionToken = UUID()
    @ObservationIgnored private var didPromptThisLaunch = false

    func start(enabled: Bool) {
        if hasSession {
            update(enabled: enabled)
            return
        }
        hasSession = true
        update(enabled: enabled)
    }

    func update(enabled: Bool) {
        guard hasSession else {
            start(enabled: enabled)
            return
        }
        guard enabled else {
            releaseFocusChange()
            activationRequested = false
            return
        }
        guard !activationRequested else { return }

        activationRequested = true
        sessionToken = UUID()
        changedFocus = false
        isActiveForSession = false
        statusMessage = nil

        let token = sessionToken
        INFocusStatusCenter.default.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self, self.sessionToken == token else { return }
                guard status == .authorized else {
                    self.statusMessage = "Allow Focus status access to preserve your existing Focus."
                    return
                }
                if INFocusStatusCenter.default.focusStatus.isFocused == true {
                    self.isActiveForSession = true
                    self.statusMessage = "A Focus was already active and will be left unchanged."
                    return
                }
                self.enableThroughControlCenter()
            }
        }
    }

    func stop() {
        hasSession = false
        activationRequested = false
        releaseFocusChange()
    }

    private func releaseFocusChange() {
        sessionToken = UUID()
        let token = sessionToken
        if changedFocus {
            do {
                try toggleThroughControlCenter()
                statusMessage = "Restoring Do Not Disturb…"
                verifyFocusState(
                    expectedFocused: false,
                    token: token,
                    successMessage: "Do Not Disturb restored."
                )
            } catch {
                statusMessage = error.localizedDescription
            }
        }
        changedFocus = false
        isActiveForSession = false
    }

    func refreshAccessibilityTrust() {
        isAccessibilityTrusted = AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    /// User-initiated only. Never call this from session start.
    func promptForAccessibilityAccess() {
        didPromptThisLaunch = true
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        isAccessibilityTrusted = AXIsProcessTrustedWithOptions(options)
        if !isAccessibilityTrusted {
            statusMessage = "Allow Study Block in Accessibility to toggle Do Not Disturb."
        }
    }

    func prepareDoNotDisturbPermission() {
        refreshAccessibilityTrust()
        guard !isAccessibilityTrusted else { return }
        statusMessage = "Allow Study Block in Accessibility to toggle Do Not Disturb."
        if !didPromptThisLaunch {
            promptForAccessibilityAccess()
        }
    }

    private func enableThroughControlCenter() {
        refreshAccessibilityTrust()
        guard isAccessibilityTrusted else {
            statusMessage = "Allow Study Block in Accessibility to toggle Do Not Disturb."
            return
        }
        do {
            try toggleThroughControlCenter()
            changedFocus = true
            isActiveForSession = true
            statusMessage = "Turning on Do Not Disturb…"
            verifyFocusState(
                expectedFocused: true,
                token: sessionToken,
                successMessage: "Do Not Disturb is on for this session."
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func verifyFocusState(
        expectedFocused: Bool,
        token: UUID,
        successMessage: String
    ) {
        Task { @MainActor [weak self] in
            for delay in [350, 650, 1_000] {
                try? await Task.sleep(for: .milliseconds(delay))
                guard let self, self.sessionToken == token else { return }
                let isFocused =
                    INFocusStatusCenter.default.focusStatus.isFocused == true
                if isFocused == expectedFocused {
                    self.statusMessage = successMessage
                    return
                }
            }
            guard let self, self.sessionToken == token else { return }
            self.statusMessage = expectedFocused
                ? "Do Not Disturb could not be confirmed as active."
                : "Do Not Disturb restoration could not be confirmed."
        }
    }

    private func toggleThroughControlCenter() throws {
        guard let menuBarAgent = NSWorkspace.shared.runningApplications.first(
            where: { $0.bundleIdentifier == "com.apple.MenuBarAgent" }
        ) else {
            throw DoNotDisturbError.controlCenter("Menu Bar Agent is unavailable.")
        }
        let application = AXUIElementCreateApplication(
            menuBarAgent.processIdentifier
        )
        guard let clockItem = findClockItem(in: application),
              let center = center(of: clockItem) else {
            throw DoNotDisturbError.controlCenter(
                "The menu bar clock could not be found."
            )
        }

        for type in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
            guard let event = CGEvent(
                mouseEventSource: nil,
                mouseType: type,
                mouseCursorPosition: center,
                mouseButton: .left
            ) else {
                throw DoNotDisturbError.controlCenter(
                    "The Control Center click could not be created."
                )
            }
            event.flags = .maskAlternate
            event.post(tap: .cghidEventTap)
        }
    }

    private func findClockItem(in root: AXUIElement) -> AXUIElement? {
        var queue = [root]
        var visited = 0
        while !queue.isEmpty, visited < 500 {
            let element = queue.removeFirst()
            visited += 1
            if stringAttribute(kAXRoleAttribute, of: element) == kAXMenuBarItemRole,
               stringAttribute(kAXDescriptionAttribute, of: element) == "Clock" {
                return element
            }
            queue.append(contentsOf: children(of: element))
        }
        return nil
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &value
        ) == .success else {
            return []
        }
        return value as? [AXUIElement] ?? []
    }

    private func stringAttribute(
        _ attribute: String,
        of element: AXUIElement
    ) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        ) == .success else {
            return nil
        }
        return value as? String
    }

    private func center(of element: AXUIElement) -> CGPoint? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        ) == .success,
        AXUIElementCopyAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            &sizeValue
        ) == .success,
        let positionValue,
        let sizeValue else {
            return nil
        }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(
            positionValue as! AXValue,
            .cgPoint,
            &position
        ),
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
            return nil
        }
        return CGPoint(
            x: position.x + size.width / 2,
            y: position.y + size.height / 2
        )
    }
}

private enum DoNotDisturbError: LocalizedError {
    case controlCenter(String)

    var errorDescription: String? {
        switch self {
        case .controlCenter(let detail):
            "Do Not Disturb could not be changed: \(detail)"
        }
    }
}
