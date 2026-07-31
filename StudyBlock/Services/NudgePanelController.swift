import AppKit
import SwiftUI

@MainActor
final class NudgePanelController {
    private let coordinator: AppEscalationCoordinator
    private var panel: NSPanel?

    init(coordinator: AppEscalationCoordinator) {
        self.coordinator = coordinator
    }

    func show() {
        let panel = panel ?? makePanel()
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        // `show()` runs while the just-activated blocked app is still
        // completing its own activation, which can otherwise reclaim key
        // window status a moment later and leave the panel's controls
        // unable to accept keyboard input. Re-asserting key window status
        // (not a second app-level activation) on the next run loop turn
        // wins that race without fighting the user's own app switch.
        DispatchQueue.main.async { [weak panel] in
            panel?.makeKeyAndOrderFront(nil)
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 410, height: 300),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Study Block"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.contentView = NSHostingView(
            rootView: AppNudgeView(coordinator: coordinator)
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.panel = panel
        return panel
    }
}
