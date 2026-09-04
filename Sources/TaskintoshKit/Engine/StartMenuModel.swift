import AppKit
import Foundation

public struct StartMenuItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: NSImage
    public let badge: String?
    public let hasSubmenu: Bool
    public let isDestructive: Bool
    public let accessibleRole: NSAccessibility.Role
    public let accessibleHelp: String
    public let action: () -> Void

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        icon: NSImage,
        badge: String? = nil,
        hasSubmenu: Bool = false,
        isDestructive: Bool = false,
        accessibleRole: NSAccessibility.Role = .menuItem,
        accessibleHelp: String = "",
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.hasSubmenu = hasSubmenu
        self.isDestructive = isDestructive
        self.accessibleRole = accessibleRole
        self.accessibleHelp = accessibleHelp.isEmpty ? title : accessibleHelp
        self.action = action
    }
}

public struct StartMenuGroup: Identifiable {
    public let id: String
    public let title: String
    public let items: [StartMenuItem]

    public init(id: String = UUID().uuidString, title: String, items: [StartMenuItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public final class MenuSearchEngine {
    public static let shared = MenuSearchEngine()

    public init() {}

    public func search(query: String, apps: [CatalogApp]) -> [StartMenuItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanQuery.isEmpty else { return [] }

        var results: [StartMenuItem] = []

        // 1. Filter applications
        for app in apps {
            if app.name.lowercased().contains(cleanQuery) {
                results.append(StartMenuItem(
                    id: app.id,
                    title: app.name,
                    subtitle: app.category,
                    icon: app.icon,
                    accessibleHelp: "Launch \(app.name)"
                ) {
                    AppCatalog.shared.launch(app)
                })
            }
        }

        // 2. Filter system locations
        let locations = MacOSLocationsService.shared
        let systemLocations: [(String, String, URL, NSImage)] = [
            ("Home", "User Home Directory", locations.homeURL, ProceduralIcons.shared.documentsIcon()),
            ("Desktop", "Desktop Directory", locations.desktopURL, ProceduralIcons.shared.documentsIcon()),
            ("Documents", "User Documents", locations.documentsURL, ProceduralIcons.shared.documentsIcon()),
            ("Downloads", "Downloads Directory", locations.downloadsURL, ProceduralIcons.shared.documentsIcon()),
            ("Applications", "Applications Folder", locations.applicationsURL, ProceduralIcons.shared.programsIcon()),
            ("Utilities", "System Utilities", locations.utilitiesURL, ProceduralIcons.shared.programsIcon()),
            ("User Library", "User Library (~/Library)", locations.userLibraryURL, ProceduralIcons.shared.documentsIcon()),
            ("System Library", "System Library (/Library)", locations.systemLibraryURL, ProceduralIcons.shared.documentsIcon()),
            ("Screenshots", "Screenshots Folder", locations.screenshotsURL, ProceduralIcons.shared.documentsIcon())
        ]

        for (name, sub, url, icon) in systemLocations {
            if name.lowercased().contains(cleanQuery) || sub.lowercased().contains(cleanQuery) {
                results.append(StartMenuItem(
                    id: url.path,
                    title: name,
                    subtitle: sub,
                    icon: icon,
                    accessibleHelp: "Open \(name)"
                ) {
                    locations.openURL(url)
                })
            }
        }

        // 3. Filter System Tools
        let tools: [(String, String, NSImage, () -> Void)] = [
            ("System Settings", "macOS System Preferences", ProceduralIcons.shared.settingsIcon(), { locations.openSystemSettings() }),
            ("Activity Monitor", "Task Manager / Process Monitor", ProceduralIcons.shared.terminalIcon(), { locations.openActivityMonitor() }),
            ("Terminal", "Command Line Shell", ProceduralIcons.shared.terminalIcon(), { locations.openTerminal() }),
            ("Accessibility Settings", "Universal Access Settings", ProceduralIcons.shared.settingsIcon(), { locations.openAccessibilitySettings() }),
            ("Force Quit", "Force Quit Running Applications", ProceduralIcons.shared.shutDownIcon(), { locations.confirmAndForceQuit() })
        ]

        for (name, sub, icon, act) in tools {
            if name.lowercased().contains(cleanQuery) || sub.lowercased().contains(cleanQuery) {
                results.append(StartMenuItem(
                    id: name,
                    title: name,
                    subtitle: sub,
                    icon: icon,
                    accessibleHelp: "Open \(name)",
                    action: act
                ))
            }
        }

        return results
    }
}
