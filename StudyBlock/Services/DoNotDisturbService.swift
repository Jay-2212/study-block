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

    @ObservationIgnored private var changedFocus = false
    @ObservationIgnored private var sessionToken = UUID()

    func start(enabled: Bool) {
        sessionToken = UUID()
        changedFocus = false
        isActiveForSession = false
        statusMessage = nil
        guard enabled else { return }

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
        sessionToken = UUID()
        if changedFocus {
            do {
                try toggleThroughControlCenter()
                statusMessage = "Do Not Disturb restored."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
        changedFocus = false
        isActiveForSession = false
    }

    private func enableThroughControlCenter() {
        guard requestAccessibilityAccess() else {
            statusMessage = "Allow Study Block in Accessibility to toggle Do Not Disturb."
            return
        }
        do {
            try toggleThroughControlCenter()
            changedFocus = true
            isActiveForSession = true
            statusMessage = "Do Not Disturb is on for this session."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func requestAccessibilityAccess() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
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
