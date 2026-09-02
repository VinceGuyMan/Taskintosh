import AppKit

public final class EraPackage {
    public let rootURL: URL?
    public let manifest: EraManifest
    public var layout: EraLayoutConfig
    public var theme: EraVisualTheme
    public var behaviors: EraBehaviorConfig
    private var assetCache: [String: NSImage] = [:]

    public init(
        rootURL: URL?,
        manifest: EraManifest,
        layout: EraLayoutConfig = EraLayoutConfig(),
        theme: EraVisualTheme = EraVisualTheme(),
        behaviors: EraBehaviorConfig = EraBehaviorConfig()
    ) {
        self.rootURL = rootURL
        self.manifest = manifest
        self.layout = layout
        self.theme = theme
        self.behaviors = behaviors
    }

    /// Loads an Era package from a directory (e.g. `Windows95.taskintosh-era`).
    public static func load(from directoryURL: URL) throws -> EraPackage {
        let manifestURL = directoryURL.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(EraManifest.self, from: manifestData)

        var layout = EraLayoutConfig()
        let layoutURL = directoryURL.appendingPathComponent("layout.json")
        if let layoutData = try? Data(contentsOf: layoutURL),
           let decodedLayout = try? JSONDecoder().decode(EraLayoutConfig.self, from: layoutData) {
            layout = decodedLayout
        }

        var theme = EraVisualTheme()
        let themeURL = directoryURL.appendingPathComponent("theme.json")
        if let themeData = try? Data(contentsOf: themeURL),
           let decodedTheme = try? JSONDecoder().decode(EraVisualTheme.self, from: themeData) {
            theme = decodedTheme
        }

        var behaviors = EraBehaviorConfig()
        let behaviorsURL = directoryURL.appendingPathComponent("behaviors.json")
        if let behaviorsData = try? Data(contentsOf: behaviorsURL),
           let decodedBehaviors = try? JSONDecoder().decode(EraBehaviorConfig.self, from: behaviorsData) {
            behaviors = decodedBehaviors
        }

        let package = EraPackage(
            rootURL: directoryURL,
            manifest: manifest,
            layout: layout,
            theme: theme,
            behaviors: behaviors
        )
        return package
    }

    /// Retrieves a cached or file-based asset image by name (e.g. "start_emblem").
    public func image(named name: String) -> NSImage? {
        if let cached = assetCache[name] {
            return cached
        }
        guard let root = rootURL else { return nil }
        let assetDir = root.appendingPathComponent("assets")
        let extensions = ["png", "svg", "pdf", "jpg", "ico"]
        for ext in extensions {
            let fileURL = assetDir.appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let image = NSImage(contentsOf: fileURL) {
                    assetCache[name] = image
                    return image
                }
            }
        }
        return nil
    }

    /// Registers an in-memory image for an asset name.
    public func registerImage(_ image: NSImage, forName name: String) {
        assetCache[name] = image
    }

    /// Default built-in Windows 95 fallback Era.
    public static func defaultEra() -> EraPackage {
        let manifest = EraManifest(
            id: "org.taskintosh.era.windows95",
            name: "Windows 95 Classic",
            version: "1.0.0",
            author: "Taskintosh Project",
            eraPeriod: "1995-1998",
            description: "Original clean-room recreation of the iconic 1995 desktop taskbar, with 3D bevels, sunken task buttons, and hierarchical Start menu."
        )
        return EraPackage(rootURL: nil, manifest: manifest)
    }
}
