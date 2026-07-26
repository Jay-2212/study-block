import AppKit

@MainActor
final class WorkspaceMonitor {
    var activationHandler: ((NSRunningApplication) -> Void)?
    private var observer: NSObjectProtocol?

    func start() {
        stop()
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[
                NSWorkspace.applicationUserInfoKey
            ] as? NSRunningApplication else {
                return
            }
            Task { @MainActor in self?.activationHandler?(app) }
        }

        if let app = NSWorkspace.shared.frontmostApplication {
            activationHandler?(app)
        }
    }

    func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
