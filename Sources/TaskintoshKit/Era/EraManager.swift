import AppKit
import Combine

public final class EraManager: ObservableObject {
    public static let shared = EraManager()

    private let activeEraKey = "Taskintosh_ActiveEraID"
    private var cancellables = Set<AnyCancellable>()

    @Published public private(set) var activeEra: EraPackage
    @Published public private(set) var availableEras: [EraPackage] = []

    public var userErasDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let taskintoshDir = appSupport.appendingPathComponent("Taskintosh", isDirectory: true)
        let erasDir = taskintoshDir.appendingPathComponent("Eras", isDirectory: true)
        if !FileManager.default.fileExists(atPath: erasDir.path) {
            try? FileManager.default.createDirectory(at: erasDir, withIntermediateDirectories: true)
        }
        return erasDir
    }

    public init() {
        let fallback = EraPackage.defaultEra()
        self.activeEra = fallback
        reloadAvailableEras()

        // Restore previously selected era if available
        if let savedID = UserDefaults.standard.string(forKey: activeEraKey) {
            selectEra(id: savedID)
        }
    }

    /// Scans bundled resources, local directories, and user Application Support for installable Eras.
    public func reloadAvailableEras() {
        var eras: [EraPackage] = []
        var seenIDs = Set<String>()

        var searchDirs: [URL] = []

        // 1. User Eras directory
        searchDirs.append(userErasDirectory)

        // 2. Bundle module resources (if available)
        #if SWIFT_PACKAGE
        if let moduleErasURL = Bundle.module.url(forResource: "Eras", withExtension: nil) {
            searchDirs.append(moduleErasURL)
        }
        #endif

        // 3. Main bundle resources
        if let mainErasURL = Bundle.main.resourceURL?.appendingPathComponent("Eras") {
            searchDirs.append(mainErasURL)
        }

        // 4. Local project development path fallback
        let devURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/TaskintoshKit/Resources/Eras")
        if FileManager.default.fileExists(atPath: devURL.path) {
            searchDirs.append(devURL)
        }

        for dir in searchDirs {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for item in contents {
                if item.pathExtension == "taskintosh-era" || (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    if let package = try? EraPackage.load(from: item) {
                        if !seenIDs.contains(package.manifest.id) {
                            seenIDs.insert(package.manifest.id)
                            eras.append(package)
                        }
                    }
                }
            }
        }

        // Fallback default if empty
        if eras.isEmpty {
            eras.append(EraPackage.defaultEra())
        }

        self.availableEras = eras

        // Ensure activeEra is one of the loaded ones if matching id
        if let match = eras.first(where: { $0.manifest.id == activeEra.manifest.id }) {
            self.activeEra = match
        } else if let first = eras.first {
            self.activeEra = first
        }
    }

    /// Selects and activates an Era by ID.
    public func selectEra(id: String) {
        guard let match = availableEras.first(where: { $0.manifest.id == id }) else { return }
        self.activeEra = match
        UserDefaults.standard.set(id, forKey: activeEraKey)
    }

    /// Selects and activates an Era by package.
    public func selectEra(_ era: EraPackage) {
        selectEra(id: era.manifest.id)
    }

    /// Imports an `.taskintosh-era` folder or archive into user storage.
    public func importEra(from sourceURL: URL) throws -> EraPackage {
        let destName = sourceURL.lastPathComponent
        let destURL = userErasDirectory.appendingPathComponent(destName)

        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        let loaded = try EraPackage.load(from: destURL)
        reloadAvailableEras()
        selectEra(id: loaded.manifest.id)
        return loaded
    }
}
