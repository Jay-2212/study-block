import AppKit
import SwiftUI

@MainActor
final class FloatingTimerPanelController {
    private static let autosaveName = "StudyBlockFloatingTimer"

    private let timer: TimerCoordinator
    private var panel: NSPanel?

    init(timer: TimerCoordinator) {
        self.timer = timer
    }

    func show() {
        let panel = panel ?? makePanel()
        restoreOrPlace(panel)
        panel.orderFrontRegardless()
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
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 88),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = DragHostingView(
            rootView: FloatingTimerView(timer: timer)
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.setFrameAutosaveName(Self.autosaveName)
        self.panel = panel
        return panel
    }

    private func restoreOrPlace(_ panel: NSPanel) {
        if panel.setFrameUsingName(Self.autosaveName, force: true) {
            clampToVisibleScreen(panel)
            return
        }
        position(panel)
    }

    private func position(_ panel: NSPanel) {
        let screen = NSApp.keyWindow?.screen
            ?? NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        let origin = NSPoint(
            x: visibleFrame.maxX - panel.frame.width - 24,
            y: visibleFrame.maxY - panel.frame.height - 24
        )
        panel.setFrameOrigin(origin)
        panel.saveFrame(usingName: Self.autosaveName)
    }

    private func clampToVisibleScreen(_ panel: NSPanel) {
        let screen = NSScreen.screens.first { $0.frame.intersects(panel.frame) }
            ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        var frame = panel.frame
        if !visibleFrame.contains(frame) {
            frame.origin.x = min(
                max(frame.origin.x, visibleFrame.minX + 8),
                visibleFrame.maxX - frame.width - 8
            )
            frame.origin.y = min(
                max(frame.origin.y, visibleFrame.minY + 8),
                visibleFrame.maxY - frame.height - 8
            )
            panel.setFrame(frame, display: true)
            panel.saveFrame(usingName: Self.autosaveName)
        }
    }
}

private final class DragHostingView<Content: View>: NSHostingView<Content> {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
