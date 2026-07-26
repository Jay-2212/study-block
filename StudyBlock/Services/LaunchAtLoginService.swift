import Observation
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLoginService {
    private(set) var isUpdating = false
    private(set) var statusMessage: String?

    func setEnabled(
        _ enabled: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        guard !isUpdating else { return }
        isUpdating = true
        statusMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
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
}
