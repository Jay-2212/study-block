import Observation
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLoginService {
    private static let registrationIdentityKey =
        "launchAtLoginRegistrationBundleIdentity"

    private(set) var isUpdating = false
    private(set) var statusMessage: String?

    func refreshRegistrationIfNeeded() {
        guard Self.isRunningFromApplications,
              UserDefaults.standard.string(
                forKey: Self.registrationIdentityKey
              ) != Self.currentRegistrationIdentity else {
            return
        }

        isUpdating = true
        let registrationIdentityKey = Self.registrationIdentityKey
        let registrationIdentity = Self.currentRegistrationIdentity
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let service = SMAppService.mainApp
            guard service.status == .enabled else {
                DispatchQueue.main.async {
                    self?.isUpdating = false
                }
                return
            }

            do {
                try service.unregister()
                try service.register()
                UserDefaults.standard.set(
                    registrationIdentity,
                    forKey: registrationIdentityKey
                )
                DispatchQueue.main.async {
                    self?.isUpdating = false
                }
            } catch {
                let message = error.localizedDescription
                DispatchQueue.main.async {
                    self?.isUpdating = false
                    self?.statusMessage =
                        "Launch at login could not be refreshed: \(message)"
                }
            }
        }
    }

    func setEnabled(
        _ enabled: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        guard !isUpdating else { return }
        isUpdating = true
        statusMessage = nil
        let registrationIdentityKey = Self.registrationIdentityKey
        let registrationIdentity = Self.currentRegistrationIdentity

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
                if enabled {
                    UserDefaults.standard.set(
                        registrationIdentity,
                        forKey: registrationIdentityKey
                    )
                } else {
                    UserDefaults.standard.removeObject(
                        forKey: registrationIdentityKey
                    )
                }
                DispatchQueue.main.async { [weak self] in
                    self?.isUpdating = false
                    self?.statusMessage = enabled
                        ? "Study Block will open when you log in."
                        : nil
                    completion(true)
                }
            } catch {
                let message = error.localizedDescription
                DispatchQueue.main.async { [weak self] in
                    self?.isUpdating = false
                    self?.statusMessage = "Launch at login could not be changed: \(message)"
                    completion(false)
                }
            }
        }
    }

    private static var isRunningFromApplications: Bool {
        let bundlePath = Bundle.main.bundleURL.standardizedFileURL.path
        return bundlePath.hasPrefix("/Applications/")
    }

    private static var currentRegistrationIdentity: String {
        let bundlePath = Bundle.main.bundleURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
        let buildVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "unknown"
        return "\(bundlePath)|\(buildVersion)"
    }
}
