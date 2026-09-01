import Foundation
import Observation

@MainActor
@Observable
final class ChromeTabPickerStore {
    var domains: [String] = []
    var statusMessage: String?
    var isScanning = false

    @ObservationIgnored private let discovery = ChromeTabDiscoveryService()
    @ObservationIgnored private var refreshTimer: Timer?
    @ObservationIgnored private var generation = UUID()

    func start() {
        scan()
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scan() }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func stop() {
        generation = UUID()
        refreshTimer?.invalidate()
        refreshTimer = nil
        isScanning = false
    }

    func scan() {
        let token = UUID()
        generation = token
        isScanning = domains.isEmpty
        discovery.discoverDomains { [weak self] result in
            guard let self, self.generation == token else { return }
            self.isScanning = false
            switch result {
            case .success(let domains):
                self.domains = domains
                self.statusMessage = nil
            case .failure(let error):
                if self.domains.isEmpty {
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }
}
