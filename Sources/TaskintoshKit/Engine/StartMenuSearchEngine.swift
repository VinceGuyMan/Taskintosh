import AppKit
import Foundation

public enum SearchResultCategory: String, CaseIterable {
    case apps = "Applications"
    case settings = "Settings & Control Panel"
    case folders = "Folders & Locations"
    case files = "Documents & Files"
    case actions = "System Commands"
}

public struct StartMenuSearchResult: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let category: SearchResultCategory
    public let icon: NSImage
    public let score: Int
    public let action: () -> Void

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        category: SearchResultCategory,
        icon: NSImage,
        score: Int = 0,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.icon = icon
        self.score = score
        self.action = action
    }
}

public final class StartMenuSearchEngine {
    public static let shared = StartMenuSearchEngine()

    private var indexedApps: [(name: String, path: String, icon: NSImage)] = []
    private var isIndexing = false
    private let indexQueue = DispatchQueue(label: "org.taskintosh.search.index", qos: .userInitiated)

    public init() {
        refreshIndex()
    }

    /// Refresh the cached list of applications in the background
    public func refreshIndex() {
        guard !isIndexing else { return }
        isIndexing = true

        indexQueue.async { [weak self] in
            var apps: [(name: String, path: String, icon: NSImage)] = []
            let fileManager = FileManager.default

            let appDirs = [
                "/Applications",
                "/System/Applications",
                "/System/Applications/Utilities",
                ("~" as NSString).expandingTildeInPath + "/Applications"
            ]

            var seenPaths = Set<String>()

            for dir in appDirs {
                guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
                for item in contents where item.hasSuffix(".app") {
                    let fullPath = (dir as NSString).appendingPathComponent(item)
                    guard !seenPaths.contains(fullPath) else { continue }
                    seenPaths.insert(fullPath)

                    let appName = (item as NSString).deletingPathExtension
                    let icon = NSWorkspace.shared.icon(forFile: fullPath)
                    apps.append((name: appName, path: fullPath, icon: icon))
                }
            }

            apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            DispatchQueue.main.async {
                self?.indexedApps = apps
                self?.isIndexing = false
            }
        }
    }

    /// Primary search function with scoring and fuzzy/prefix ranking
    public func search(query: String, era: EraPackage? = nil) -> [StartMenuSearchResult] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanQuery.isEmpty else { return [] }

        var results: [StartMenuSearchResult] = []
        let locations = MacOSLocationsService.shared
        let activeEra = era ?? EraManager.shared.activeEra

        // 1. Search Indexed Applications
        for app in indexedApps {
            let nameLower = app.name.lowercased()
            var score = 0

            if nameLower == cleanQuery {
                score = 100
            } else if nameLower.hasPrefix(cleanQuery) {
                score = 80
            } else if nameLower.contains(" " + cleanQuery) {
                score = 60
            } else if nameLower.contains(cleanQuery) {
                score = 40
            }

            if score > 0 {
                let targetPath = app.path
                results.append(StartMenuSearchResult(
                    id: "app:\(app.path)",
                    title: app.name,
                    subtitle: "Application",
                    category: .apps,
                    icon: app.icon,
                    score: score,
                    action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: targetPath))
                    }
                ))
            }
        }

        // 2. Search Settings & Control Panel
        let settingsItems: [(name: String, sub: String, iconType: SystemIconType, action: () -> Void)] = [
            ("System Settings", "macOS System Preferences", .settings, { locations.openSystemSettings() }),
            ("Control Panel", "macOS System Settings", .controlPanel, { locations.openSystemSettings() }),
            ("Accessibility Settings", "Accessibility Preferences", .accessibility, { locations.openAccessibilitySettings() }),
            ("Network Settings", "Wi-Fi, Ethernet & Network", .network, { locations.openSystemSettings() }),
            ("Sound Settings", "Sound & Audio Preferences", .settings, { locations.openSystemSettings() }),
            ("Displays Settings", "Monitors & Resolution", .settings, { locations.openSystemSettings() }),
            ("Date & Time Settings", "Clock & Time Zone", .settings, { locations.openSystemSettings() }),
            ("Taskintosh Era Manager", "Themes & Historical Eras", .eraManager, {
                NotificationCenter.default.post(name: NSNotification.Name("OpenEraManager"), object: nil)
            })
        ]

        for (name, sub, iconType, act) in settingsItems {
            let nameLower = name.lowercased()
            let subLower = sub.lowercased()
            var score = 0

            if nameLower == cleanQuery {
                score = 95
            } else if nameLower.hasPrefix(cleanQuery) {
                score = 75
            } else if nameLower.contains(cleanQuery) || subLower.contains(cleanQuery) {
                score = 45
            }

            if score > 0 {
                let icon = ProceduralIcons.shared.icon(for: iconType, era: activeEra, size: 24)
                results.append(StartMenuSearchResult(
                    id: "setting:\(name)",
                    title: name,
                    subtitle: sub,
                    category: .settings,
                    icon: icon,
                    score: score,
                    action: act
                ))
            }
        }

        // 3. Search Common Folders & Locations
        let musicURL = locations.homeURL.appendingPathComponent("Music")
        let folderItems: [(name: String, sub: String, url: URL, iconType: SystemIconType)] = [
            ("Documents", "User Documents", locations.documentsURL, .documents),
            ("Downloads", "Downloads Directory", locations.downloadsURL, .documents),
            ("Desktop", "Desktop Directory", locations.desktopURL, .documents),
            ("Pictures", "Photos & Images", locations.picturesURL, .pictures),
            ("Screenshots", "Recent Screen Captures", locations.screenshotsURL, .pictures),
            ("Music", "Audio & Music", musicURL, .music),
            ("Home", "User Home Directory", locations.homeURL, .folder),
            ("Applications", "Applications Directory", locations.applicationsURL, .programs),
            ("Utilities", "System Utilities", locations.utilitiesURL, .programs),
            ("User Library", "User Library (~/Library)", locations.userLibraryURL, .documents),
            ("System Library", "System Library (/Library)", locations.systemLibraryURL, .documents),
            ("Computer", "Mounted Volumes & Disks", URL(fileURLWithPath: "/Volumes"), .myComputer),
            ("External Volumes", "Connected External Disks", URL(fileURLWithPath: "/Volumes"), .myComputer)
        ]

        for (name, sub, url, iconType) in folderItems {
            let nameLower = name.lowercased()
            var score = 0

            if nameLower == cleanQuery {
                score = 90
            } else if nameLower.hasPrefix(cleanQuery) {
                score = 70
            } else if nameLower.contains(cleanQuery) {
                score = 35
            }

            if score > 0 {
                let targetURL = url
                let icon = ProceduralIcons.shared.icon(for: iconType, era: activeEra, size: 24)
                results.append(StartMenuSearchResult(
                    id: "folder:\(url.path)",
                    title: name,
                    subtitle: sub,
                    category: .folders,
                    icon: icon,
                    score: score,
                    action: {
                        locations.openURL(targetURL)
                    }
                ))
            }
        }

        // 4. Search System Actions
        let actionItems: [(name: String, sub: String, iconType: SystemIconType, action: () -> Void)] = [
            ("Terminal", "Command Line Prompt", .terminal, { locations.openTerminal() }),
            ("Activity Monitor", "Task Manager", .terminal, { locations.openActivityMonitor() }),
            ("Run...", "Run Application or Path", .run, {
                NotificationCenter.default.post(name: NSNotification.Name("OpenRunDialog"), object: nil)
            }),
            ("Go to Path...", "Navigate directly to path", .goToPath, {
                NotificationCenter.default.post(name: NSNotification.Name("OpenGoToPathDialog"), object: nil)
            }),
            ("Force Quit...", "Force Quit Running Applications", .forceQuit, { locations.confirmAndForceQuit() }),
            ("Lock Screen", "Lock macOS session", .lock, {
                let script = "tell application \"System Events\" to sleep"
                if let asObj = NSAppleScript(source: script) {
                    var err: NSDictionary?
                    asObj.executeAndReturnError(&err)
                }
            }),
            ("Log Off...", "Log off current user", .logOff, { locations.confirmAndLogOut() }),
            ("Shut Down...", "Turn off computer", .shutDown, {
                NotificationCenter.default.post(name: NSNotification.Name("OpenShutDownDialog"), object: nil)
            })
        ]

        for (name, sub, iconType, act) in actionItems {
            let nameLower = name.lowercased()
            var score = 0

            if nameLower == cleanQuery {
                score = 90
            } else if nameLower.hasPrefix(cleanQuery) {
                score = 70
            } else if nameLower.contains(cleanQuery) {
                score = 35
            }

            if score > 0 {
                let icon = ProceduralIcons.shared.icon(for: iconType, era: activeEra, size: 24)
                results.append(StartMenuSearchResult(
                    id: "action:\(name)",
                    title: name,
                    subtitle: sub,
                    category: .actions,
                    icon: icon,
                    score: score,
                    action: act
                ))
            }
        }

        // 5. Search Recent Documents
        let recents = NSDocumentController.shared.recentDocumentURLs
        for fileURL in recents.prefix(15) {
            let fileName = fileURL.lastPathComponent
            let nameLower = fileName.lowercased()
            if nameLower.contains(cleanQuery) {
                let targetURL = fileURL
                let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
                results.append(StartMenuSearchResult(
                    id: "file:\(fileURL.path)",
                    title: fileName,
                    subtitle: fileURL.deletingLastPathComponent().path,
                    category: .files,
                    icon: icon,
                    score: nameLower.hasPrefix(cleanQuery) ? 55 : 30,
                    action: {
                        locations.openURL(targetURL)
                    }
                ))
            }
        }

        // Sort by score descending, then alphabetically
        results.sort {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }

        return results
    }
}
