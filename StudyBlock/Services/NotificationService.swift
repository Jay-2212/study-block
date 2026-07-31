import Foundation
import Observation
import UserNotifications

/// Wraps `UNUserNotificationCenter` so session-complete feedback reaches the
/// user even when Study Block isn't frontmost. Authorization is requested
/// once, from a user-initiated action (onboarding's permission-priming step,
/// or the ready-screen affordance for existing installs) — never silently.
@MainActor
@Observable
final class NotificationService: NSObject {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
            Task { @MainActor in
                self?.refreshAuthorizationStatus()
            }
        }
    }

    func notifySessionCompleted(body: String) {
        guard authorizationStatus == .authorized
            || authorizationStatus == .provisional else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Focus session complete"
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
