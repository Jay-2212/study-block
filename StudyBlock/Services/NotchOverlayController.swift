import AppKit
import SwiftUI

@MainActor
final class NotchOverlayController {
    private let timer: TimerCoordinator
    private var panel: NSPanel?
    private var screenObserver: NSObjectProtocol?

    init(timer: TimerCoordinator) {
        self.timer = timer
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reposition()
            }
        }
    }

    func show() {
        let panel = panel ?? makePanel()
        reposition(panel)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true
        panel.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        panel.collectionBehavior = [.stationary, .canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false

        let hasNotch = Self.screenHasNotch
        panel.contentView = NSHostingView(
            rootView: NotchOutlineView(timer: timer, hasNotch: hasNotch)
        )
        self.panel = panel
        return panel
    }

    private func reposition(_ targetPanel: NSPanel? = nil) {
        guard let panel = targetPanel ?? self.panel,
              let screen = NSScreen.main else { return }

        let hasNotch = Self.screenHasNotch
        let width: CGFloat = hasNotch ? 220 : 140
        let height: CGFloat = hasNotch ? 40 : 32

        panel.contentView = NSHostingView(
            rootView: NotchOutlineView(timer: timer, hasNotch: hasNotch)
        )

        let x = screen.frame.origin.x + (screen.frame.width - width) / 2
        let y = screen.frame.origin.y + screen.frame.height - height

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    static var screenHasNotch: Bool {
        guard let screen = NSScreen.main else { return false }
        return screen.safeAreaInsets.top > 0
    }
}
