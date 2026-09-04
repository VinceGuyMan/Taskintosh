import AppKit
import Foundation
import Combine

/// A model representing a pinned program, shortcut, or tile within the Start Menu.
public struct PinnedProgramItem: Codable, Identifiable, Equatable {
    public let id: String
    public var title: String
    public var subtitle: String?
    public var path: String?
    public var iconType: String
    public var isWide: Bool
    public var groupName: String?
    public var colorHex: String?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        path: String? = nil,
        iconType: String = "programs",
        isWide: Bool = false,
        groupName: String? = nil,
        colorHex: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.path = path
        self.iconType = iconType
        self.isWide = isWide
        self.groupName = groupName
        self.colorHex = colorHex
    }
}

/// Central manager and persistence engine for pinned programs across Windows eras.
public final class PinnedProgramsManager: ObservableObject {
    public static let shared = PinnedProgramsManager()

    private let persistencePrefix = "Taskintosh_PinnedPrograms_"
    private let userDefaults: UserDefaults

    @Published public private(set) var updateCounter: Int = 0

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Era Key Normalization

    public func storageKey(for eraID: String) -> String {
        return persistencePrefix + eraID
    }

    // MARK: - Query & Mutation

    /// Retrieves current pinned programs for the specified era, falling back to defaults only if it has not yet been customized.
    public func pinnedPrograms(for eraID: String) -> [PinnedProgramItem] {
        let key = storageKey(for: eraID)
        if let data = userDefaults.data(forKey: key),
           let items = try? JSONDecoder().decode([PinnedProgramItem].self, from: data) {
            return items
        }
        return defaultPrograms(for: eraID)
    }

    /// Checks if a program is already pinned in the specified era.
    public func isPinned(id: String, in eraID: String) -> Bool {
        return pinnedPrograms(for: eraID).contains { $0.id == id }
    }

    /// Pins a program in the specified era. Prevents duplicates by moving existing item or appending.
    public func pin(item: PinnedProgramItem, in eraID: String) {
        var current = pinnedPrograms(for: eraID)
        if let existingIdx = current.firstIndex(where: { $0.id == item.id }) {
            current.remove(at: existingIdx)
        }
        current.append(item)
        save(items: current, for: eraID)
    }

    /// Unpins a program by ID from the specified era.
    public func unpin(id: String, in eraID: String) {
        var current = pinnedPrograms(for: eraID)
        current.removeAll { $0.id == id }
        save(items: current, for: eraID)
    }

    /// Reorders a pinned program from a source index to a target destination index with bounds safety.
    @discardableResult
    public func reorder(fromIndex: Int, toIndex: Int, in eraID: String) -> Bool {
        var current = pinnedPrograms(for: eraID)
        guard !current.isEmpty else { return false }

        let clampedFrom = max(0, min(current.count - 1, fromIndex))
        let clampedTo = max(0, min(current.count - 1, toIndex))
        guard clampedFrom != clampedTo else { return false }

        let item = current.remove(at: clampedFrom)
        current.insert(item, at: clampedTo)
        save(items: current, for: eraID)
        return true
    }

    /// Moves a pinned program identified by ID to a target index.
    @discardableResult
    public func moveItem(id: String, toIndex: Int, in eraID: String) -> Bool {
        let current = pinnedPrograms(for: eraID)
        guard let idx = current.firstIndex(where: { $0.id == id }) else { return false }
        return reorder(fromIndex: idx, toIndex: toIndex, in: eraID)
    }

    /// Resets pinned programs for the specified era to its canonical historical defaults.
    public func resetToDefaults(for eraID: String) {
        let key = storageKey(for: eraID)
        userDefaults.removeObject(forKey: key)
        updateCounter += 1
    }

    /// Resets all eras to defaults.
    public func resetAllToDefaults() {
        let eraIDs = [
            "org.taskintosh.era.windows95",
            "org.taskintosh.era.windowsxp",
            "org.taskintosh.era.windows7",
            "org.taskintosh.era.windows8",
            "org.taskintosh.era.windows81",
            "org.taskintosh.era.windows10",
            "org.taskintosh.era.windows11"
        ]
        for eraID in eraIDs {
            resetToDefaults(for: eraID)
        }
    }

    private func save(items: [PinnedProgramItem], for eraID: String) {
        let key = storageKey(for: eraID)
        if let data = try? JSONEncoder().encode(items) {
            userDefaults.set(data, forKey: key)
        }
        updateCounter += 1
    }

    // MARK: - Era Historical Defaults

    public func defaultPrograms(for eraID: String) -> [PinnedProgramItem] {
        switch eraID {
        case "org.taskintosh.era.windowsxp":
            return [
                PinnedProgramItem(id: "xp.internet", title: "Internet", subtitle: "Safari / Web Browser", path: "/Applications/Safari.app", iconType: "internet"),
                PinnedProgramItem(id: "xp.email", title: "E-Mail", subtitle: "Mail & Messages", path: "/System/Applications/Mail.app", iconType: "email"),
                PinnedProgramItem(id: "xp.update", title: "Windows Update", subtitle: "System Updates", iconType: "settings"),
                PinnedProgramItem(id: "xp.terminal", title: "Terminal", subtitle: "Command Prompt", path: "/System/Applications/Utilities/Terminal.app", iconType: "terminal"),
                PinnedProgramItem(id: "xp.vscode", title: "Visual Studio Code", subtitle: "Developer Tools", path: "/Applications/Visual Studio Code.app", iconType: "terminal"),
                PinnedProgramItem(id: "xp.calc", title: "Calculator", subtitle: "Accessories", path: "/System/Applications/Calculator.app", iconType: "programs"),
                PinnedProgramItem(id: "xp.textedit", title: "TextEdit", subtitle: "Word Processor", path: "/System/Applications/TextEdit.app", iconType: "documents")
            ]

        case "org.taskintosh.era.windows7":
            return [
                PinnedProgramItem(id: "w7.safari", title: "Safari / Internet", path: "/Applications/Safari.app", iconType: "internet"),
                PinnedProgramItem(id: "w7.vscode", title: "Visual Studio Code", path: "/Applications/Visual Studio Code.app", iconType: "terminal"),
                PinnedProgramItem(id: "w7.terminal", title: "Terminal", path: "/System/Applications/Utilities/Terminal.app", iconType: "terminal"),
                PinnedProgramItem(id: "w7.calc", title: "Calculator", path: "/System/Applications/Calculator.app", iconType: "programs"),
                PinnedProgramItem(id: "w7.textedit", title: "TextEdit", path: "/System/Applications/TextEdit.app", iconType: "documents"),
                PinnedProgramItem(id: "w7.actmon", title: "Activity Monitor", path: "/System/Applications/Utilities/Activity Monitor.app", iconType: "terminal")
            ]

        case "org.taskintosh.era.windows8", "org.taskintosh.era.windows81":
            return [
                // Group: Apps
                PinnedProgramItem(id: "w8.desktop", title: "Desktop", subtitle: "macOS Desktop", iconType: "myComputer", isWide: true, groupName: "Apps", colorHex: "#0D74BF"),
                PinnedProgramItem(id: "w8.internet", title: "Internet", subtitle: "Browser", path: "/Applications/Safari.app", iconType: "internet", isWide: false, groupName: "Apps", colorHex: "#1F94F3"),
                PinnedProgramItem(id: "w8.terminal", title: "Terminal", subtitle: "Shell", path: "/System/Applications/Utilities/Terminal.app", iconType: "terminal", isWide: false, groupName: "Apps", colorHex: "#262626"),
                PinnedProgramItem(id: "w8.calc", title: "Calculator", subtitle: "Math", path: "/System/Applications/Calculator.app", iconType: "programs", isWide: false, groupName: "Apps", colorHex: "#008C73"),
                PinnedProgramItem(id: "w8.settings", title: "Settings", subtitle: "PC Settings", iconType: "settings", isWide: false, groupName: "Apps", colorHex: "#7333A6"),

                // Group: macOS Locations
                PinnedProgramItem(id: "w8.docs", title: "Documents", subtitle: "~/Documents", iconType: "documents", isWide: false, groupName: "macOS Locations", colorHex: "#D9661A"),
                PinnedProgramItem(id: "w8.downloads", title: "Downloads", subtitle: "~/Downloads", iconType: "documents", isWide: false, groupName: "macOS Locations", colorHex: "#1A9973"),
                PinnedProgramItem(id: "w8.pictures", title: "Pictures", subtitle: "Photos & Captures", iconType: "pictures", isWide: false, groupName: "macOS Locations", colorHex: "#CC8C26"),
                PinnedProgramItem(id: "w8.computer", title: "Computer", subtitle: "Mounted Volumes", iconType: "myComputer", isWide: false, groupName: "macOS Locations", colorHex: "#3359A6"),
                PinnedProgramItem(id: "w8.userlib", title: "User Library", subtitle: "~/Library", iconType: "folder", isWide: false, groupName: "macOS Locations", colorHex: "#B33340"),
                PinnedProgramItem(id: "w8.syslib", title: "System Library", subtitle: "/Library", iconType: "folder", isWide: false, groupName: "macOS Locations", colorHex: "#802633"),

                // Group: Control & Tools
                PinnedProgramItem(id: "w8.actmon", title: "Activity Monitor", subtitle: "Task Manager", iconType: "terminal", isWide: false, groupName: "Control & Tools", colorHex: "#404059"),
                PinnedProgramItem(id: "w8.access", title: "Accessibility", subtitle: "Preferences", iconType: "accessibility", isWide: false, groupName: "Control & Tools", colorHex: "#26808C"),
                PinnedProgramItem(id: "w8.forcequit", title: "Force Quit", subtitle: "Quit Apps", iconType: "forceQuit", isWide: false, groupName: "Control & Tools", colorHex: "#CC2626"),
                PinnedProgramItem(id: "w8.era", title: "Taskintosh", subtitle: "Era Manager", iconType: "eraManager", isWide: false, groupName: "Control & Tools", colorHex: "#0D8CB3"),
                PinnedProgramItem(id: "w8.update", title: "Windows Update", subtitle: "System Updates", iconType: "settings", isWide: false, groupName: "Control & Tools", colorHex: "#0073BF"),
                PinnedProgramItem(id: "w8.path", title: "Go to Path...", subtitle: "Path Navigator", iconType: "goToPath", isWide: false, groupName: "Control & Tools", colorHex: "#4D6699"),
                PinnedProgramItem(id: "w8.run", title: "Run...", subtitle: "Run Command", iconType: "run", isWide: false, groupName: "Control & Tools", colorHex: "#267359"),

                // Group: Power
                PinnedProgramItem(id: "w8.sleep", title: "Sleep", subtitle: "Standby", iconType: "lock", isWide: false, groupName: "Power", colorHex: "#4D5973"),
                PinnedProgramItem(id: "w8.restart", title: "Restart", subtitle: "Reboot Mac", iconType: "restart", isWide: false, groupName: "Power", colorHex: "#BF591A"),
                PinnedProgramItem(id: "w8.shutdown", title: "Shut Down", subtitle: "Power Off", iconType: "shutDown", isWide: false, groupName: "Power", colorHex: "#D91A26")
            ]

        case "org.taskintosh.era.windows10":
            return [
                PinnedProgramItem(id: "w10.browser", title: "Browser", path: "/Applications/Safari.app", iconType: "internet", isWide: false, colorHex: "#0078D7"),
                PinnedProgramItem(id: "w10.mail", title: "Mail", path: "/System/Applications/Mail.app", iconType: "email", isWide: false, colorHex: "#0066BF"),
                PinnedProgramItem(id: "w10.terminal", title: "Terminal", path: "/System/Applications/Utilities/Terminal.app", iconType: "terminal", isWide: true, colorHex: "#1F1F1F"),
                PinnedProgramItem(id: "w10.calc", title: "Calculator", path: "/System/Applications/Calculator.app", iconType: "programs", isWide: false, colorHex: "#1A8C73"),
                PinnedProgramItem(id: "w10.settings", title: "Settings", iconType: "settings", isWide: false, colorHex: "#66338C"),
                PinnedProgramItem(id: "w10.docs", title: "Documents", iconType: "documents", isWide: false, colorHex: "#D9661A"),
                PinnedProgramItem(id: "w10.downloads", title: "Downloads", iconType: "documents", isWide: false, colorHex: "#268C73"),
                PinnedProgramItem(id: "w10.pictures", title: "Pictures", iconType: "pictures", isWide: false, colorHex: "#BF7326"),
                PinnedProgramItem(id: "w10.computer", title: "Computer", iconType: "myComputer", isWide: false, colorHex: "#3359A6"),
                PinnedProgramItem(id: "w10.era", title: "Taskintosh", iconType: "eraManager", isWide: true, colorHex: "#0073BF"),
                PinnedProgramItem(id: "w10.update", title: "Windows Update", iconType: "settings", isWide: false, colorHex: "#0066B8")
            ]

        case "org.taskintosh.era.windows11":
            return [
                PinnedProgramItem(id: "w11.safari", title: "Safari", path: "/Applications/Safari.app", iconType: "internet"),
                PinnedProgramItem(id: "w11.mail", title: "Mail", path: "/System/Applications/Mail.app", iconType: "email"),
                PinnedProgramItem(id: "w11.terminal", title: "Terminal", path: "/System/Applications/Utilities/Terminal.app", iconType: "terminal"),
                PinnedProgramItem(id: "w11.vscode", title: "VS Code", path: "/Applications/Visual Studio Code.app", iconType: "terminal"),
                PinnedProgramItem(id: "w11.settings", title: "Settings", iconType: "settings"),
                PinnedProgramItem(id: "w11.actmon", title: "Activity Mon", path: "/System/Applications/Utilities/Activity Monitor.app", iconType: "terminal"),
                PinnedProgramItem(id: "w11.calc", title: "Calculator", path: "/System/Applications/Calculator.app", iconType: "programs"),
                PinnedProgramItem(id: "w11.textedit", title: "TextEdit", path: "/System/Applications/TextEdit.app", iconType: "documents"),
                PinnedProgramItem(id: "w11.files", title: "Files", iconType: "documents"),
                PinnedProgramItem(id: "w11.access", title: "Accessibility", iconType: "accessibility"),
                PinnedProgramItem(id: "w11.era", title: "Taskintosh", iconType: "eraManager"),
                PinnedProgramItem(id: "w11.path", title: "Go to Path", iconType: "goToPath")
            ]

        default:
            return [
                PinnedProgramItem(id: "default.safari", title: "Browser", path: "/Applications/Safari.app", iconType: "internet"),
                PinnedProgramItem(id: "default.terminal", title: "Terminal", path: "/System/Applications/Utilities/Terminal.app", iconType: "terminal"),
                PinnedProgramItem(id: "default.settings", title: "Settings", iconType: "settings")
            ]
        }
    }
}
