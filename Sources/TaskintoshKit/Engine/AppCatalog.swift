import AppKit
import Combine

public struct CatalogApp: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let url: URL
    public let icon: NSImage
    public let category: String

    public init(id: String, name: String, url: URL, icon: NSImage, category: String = "Programs") {
        self.id = id
        self.name = name
        self.url = url
        self.icon = icon
        self.category = category
    }

    public static func == (lhs: CatalogApp, rhs: CatalogApp) -> Bool {
        lhs.id == rhs.id
    }
}

public final class AppCatalog: ObservableObject {
    public static let shared = AppCatalog()

    @Published public private(set) var installedApps: [CatalogApp] = []
    @Published public private(set) var categories: [String: [CatalogApp]] = [:]
    @Published public private(set) var isScanning: Bool = false

    private let fileManager = FileManager.default
    private let workspace = NSWorkspace.shared

    public init() {
        scanApplicationsAsync()
    }

    public func scanApplicationsAsync() {
        guard !isScanning else { return }
        isScanning = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let apps = self.scanAllDirectories()

            var catMap: [String: [CatalogApp]] = [:]
            for app in apps {
                catMap[app.category, default: []].append(app)
            }
            for (key, list) in catMap {
                catMap[key] = list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }

            DispatchQueue.main.async {
                self.installedApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.categories = catMap
                self.isScanning = false
            }
        }
    }

    private func scanAllDirectories() -> [CatalogApp] {
        var results: [CatalogApp] = []
        var seenPaths = Set<String>()

        let searchLocations: [(URL, String)] = [
            (URL(fileURLWithPath: "/System/Applications/Utilities"), "Accessories/Utilities"),
            (URL(fileURLWithPath: "/System/Applications"), "Programs"),
            (URL(fileURLWithPath: "/Applications"), "Programs"),
            (FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"), "User Apps")
        ]

        for (dirURL, defaultCat) in searchLocations {
            guard fileManager.fileExists(atPath: dirURL.path) else { continue }
            guard let enumerator = fileManager.enumerator(
                at: dirURL,
                includingPropertiesForKeys: [.isApplicationKey, .nameKey],
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "app" && !seenPaths.contains(fileURL.path) {
                    seenPaths.insert(fileURL.path)

                    let bundle = Bundle(url: fileURL)
                    let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                        ?? fileURL.deletingPathExtension().lastPathComponent

                    let icon = workspace.icon(forFile: fileURL.path)

                    var category = defaultCat
                    let parentName = fileURL.deletingLastPathComponent().lastPathComponent
                    if parentName == "Utilities" {
                        category = "Accessories/Utilities"
                    }

                    results.append(CatalogApp(
                        id: fileURL.path,
                        name: displayName,
                        url: fileURL,
                        icon: icon,
                        category: category
                    ))
                }
            }
        }

        return results
    }

    public func launch(_ app: CatalogApp) {
        workspace.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
    }
}
