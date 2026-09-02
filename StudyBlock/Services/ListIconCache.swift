import AppKit
import CryptoKit
import Foundation
import Observation

enum ListIconSource: Hashable {
    case website(String)
    case application(String)
    case system(String)
}

actor WebsiteIconCache {
    static let shared = WebsiteIconCache()

    private let memory = NSCache<NSString, NSData>()
    private var unavailable: Set<String> = []
    private let cacheDirectory: URL

    private init() {
        memory.countLimit = 200
        memory.totalCostLimit = 10 * 1024 * 1024 // 10 MB limit
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        cacheDirectory = applicationSupport
            .appendingPathComponent("Study Block", isDirectory: true)
            .appendingPathComponent("Website Icons", isDirectory: true)
    }

    func iconData(for domain: String) async -> Data? {
        let normalized = domain.lowercased()
        let cacheKey = normalized as NSString
        if let cached = memory.object(forKey: cacheKey) {
            return cached as Data
        }
        guard !unavailable.contains(normalized) else { return nil }

        let diskURL = cacheURL(for: normalized)
        if let data = try? Data(contentsOf: diskURL),
           NSImage(data: data) != nil {
            memory.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            return data
        }

        guard let url = URL(string: "https://\(normalized)/favicon.ico") else {
            unavailable.insert(normalized)
            return nil
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 5
        )
        request.setValue("image/*", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  data.count <= 2_000_000,
                  NSImage(data: data) != nil else {
                unavailable.insert(normalized)
                return nil
            }
            memory.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            try? FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
            try? data.write(to: diskURL, options: .atomic)
            return data
        } catch {
            unavailable.insert(normalized)
            return nil
        }
    }

    private func cacheURL(for domain: String) -> URL {
        let digest = SHA256.hash(data: Data(domain.utf8))
        let filename = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent("\(filename).icon")
    }
}

@MainActor
final class ApplicationIconCache {
    static let shared = ApplicationIconCache()

    private let cache = NSCache<NSString, NSImage>()
    private var unavailable: Set<String> = []

    private init() {}

    func icon(for bundleIdentifier: String) -> NSImage? {
        let key = bundleIdentifier as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard !unavailable.contains(bundleIdentifier),
              let url = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleIdentifier
              ) else {
            unavailable.insert(bundleIdentifier)
            return nil
        }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(image, forKey: key)
        return image
    }
}

@MainActor
@Observable
final class ListIconStore {
    private var images: [ListIconSource: NSImage] = [:]
    @ObservationIgnored private var loading: Set<ListIconSource> = []
    @ObservationIgnored private var unavailable: Set<ListIconSource> = []

    func image(for source: ListIconSource) -> NSImage? {
        images[source]
    }

    func load(_ source: ListIconSource) {
        guard images[source] == nil,
              !loading.contains(source),
              !unavailable.contains(source) else {
            return
        }
        loading.insert(source)

        Task {
            let image: NSImage?
            switch source {
            case .website(let domain):
                if let data = await WebsiteIconCache.shared.iconData(
                    for: domain
                ) {
                    image = NSImage(data: data)
                } else {
                    image = nil
                }
            case .application(let bundleIdentifier):
                await Task.yield()
                image = ApplicationIconCache.shared.icon(
                    for: bundleIdentifier
                )
            case .system:
                image = nil
            }

            loading.remove(source)
            if let image {
                images[source] = image
            } else {
                unavailable.insert(source)
            }
        }
    }
}
