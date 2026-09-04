import AppKit
import Foundation

public struct VolumeItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let url: URL
    public let isRemovable: Bool

    public init(id: String, name: String, url: URL, isRemovable: Bool) {
        self.id = id
        self.name = name
        self.url = url
        self.isRemovable = isRemovable
    }
}

public final class MacOSLocationsService {
    public static let shared = MacOSLocationsService()

    private let fileManager = FileManager.default
    private let workspace = NSWorkspace.shared

    public init() {}

    // MARK: - Core Paths

    public var homeURL: URL {
        fileManager.homeDirectoryForCurrentUser
    }

    public var desktopURL: URL {
        homeURL.appendingPathComponent("Desktop")
    }

    public var documentsURL: URL {
        homeURL.appendingPathComponent("Documents")
    }

    public var downloadsURL: URL {
        homeURL.appendingPathComponent("Downloads")
    }

    public var picturesURL: URL {
        homeURL.appendingPathComponent("Pictures")
    }

    public var applicationsURL: URL {
        URL(fileURLWithPath: "/Applications")
    }

    public var utilitiesURL: URL {
        let sysUtilities = URL(fileURLWithPath: "/System/Applications/Utilities")
        if fileManager.fileExists(atPath: sysUtilities.path) {
            return sysUtilities
        }
        return URL(fileURLWithPath: "/Applications/Utilities")
    }

    /// User's personal Library directory (~/Library)
    public var userLibraryURL: URL {
        homeURL.appendingPathComponent("Library")
    }

    /// System-wide Library directory (/Library)
    public var systemLibraryURL: URL {
        URL(fileURLWithPath: "/Library")
    }

    /// Returns custom screenshots path or default Desktop/Pictures
    public var screenshotsURL: URL {
        // Read screencapture default location if set
        if let custom = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture")?["location"] as? String {
            let expanded = NSString(string: custom).expandingTildeInPath
            if fileManager.fileExists(atPath: expanded) {
                return URL(fileURLWithPath: expanded)
            }
        }
        let screenshotsDir = picturesURL.appendingPathComponent("Screenshots")
        if fileManager.fileExists(atPath: screenshotsDir.path) {
            return screenshotsDir
        }
        return desktopURL
    }

    /// iCloud Drive URL if configured and available
    public var iCloudDriveURL: URL? {
        let url = userLibraryURL
            .appendingPathComponent("Mobile Documents")
            .appendingPathComponent("com~apple~CloudDocs")
        if fileManager.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }

    /// List mounted volumes in /Volumes excluding root
    public func externalVolumes() -> [VolumeItem] {
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        guard let contents = try? fileManager.contentsOfDirectory(at: volumesURL, includingPropertiesForKeys: [.volumeIsRemovableKey, .volumeIsLocalKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        var results: [VolumeItem] = []
        for url in contents {
            // Skip root filesystem link
            if url.path == "/" || url.lastPathComponent == "Macintosh HD" {
                continue
            }
            let isRemovable = (try? url.resourceValues(forKeys: [.volumeIsRemovableKey]))?.volumeIsRemovable ?? false
            results.append(VolumeItem(
                id: url.path,
                name: url.lastPathComponent,
                url: url,
                isRemovable: isRemovable
            ))
        }
        return results
    }

    /// Query recent documents via NSDocumentController or Recent items
    public func recentDocumentURLs(limit: Int = 10) -> [URL] {
        let recent = NSDocumentController.shared.recentDocumentURLs
        if !recent.isEmpty {
            return Array(recent.prefix(limit))
        }

        // Fallback: look in user's recent items directory
        let recentFolders = userLibraryURL.appendingPathComponent("RecentFolders")
        if let items = try? fileManager.contentsOfDirectory(at: recentFolders, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            return Array(items.prefix(limit))
        }
        return []
    }

    // MARK: - Safe Actions & Navigation

    public func openURL(_ url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            workspace.open(url)
        } else {
            showErrorAlert(title: "Location Not Found", message: "The location '\(url.path)' does not exist or is currently unavailable.")
        }
    }

    public func revealInFinder(url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            workspace.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        } else {
            showErrorAlert(title: "Location Not Found", message: "The item '\(url.lastPathComponent)' could not be found.")
        }
    }

    public func openFileDialog(title: String = "Open File", completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            completion(panel.url)
        } else {
            completion(nil)
        }
    }

    public func openFolderDialog(title: String = "Open Folder", completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            completion(panel.url)
        } else {
            completion(nil)
        }
    }

    // MARK: - System Tools Launchers

    public func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:") {
            workspace.open(url)
        } else {
            let appURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
            workspace.open(appURL)
        }
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess") {
            workspace.open(url)
        } else {
            openSystemSettings()
        }
    }

    public func openActivityMonitor() {
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        workspace.open(URL(fileURLWithPath: path))
    }

    public func openTerminal() {
        let path = "/System/Applications/Utilities/Terminal.app"
        workspace.open(URL(fileURLWithPath: path))
    }

    // MARK: - Destructive System Actions (With Required Confirmation)

    public func confirmAndShutDown(parentWindow: NSWindow? = nil) {
        showConfirmationAlert(
            title: "Shut Down",
            message: "Are you sure you want to shut down your Mac?",
            actionButtonTitle: "Shut Down",
            parentWindow: parentWindow
        ) {
            let script = "tell application \"System Events\" to shut down"
            self.executeAppleScript(script)
        }
    }

    public func confirmAndRestart(parentWindow: NSWindow? = nil) {
        showConfirmationAlert(
            title: "Restart",
            message: "Are you sure you want to restart your Mac?",
            actionButtonTitle: "Restart",
            parentWindow: parentWindow
        ) {
            let script = "tell application \"System Events\" to restart"
            self.executeAppleScript(script)
        }
    }

    public func confirmAndSleep(parentWindow: NSWindow? = nil) {
        showConfirmationAlert(
            title: "Sleep",
            message: "Are you sure you want to put your Mac to sleep?",
            actionButtonTitle: "Sleep",
            parentWindow: parentWindow
        ) {
            let script = "tell application \"System Events\" to sleep"
            self.executeAppleScript(script)
        }
    }

    public func confirmAndLogOut(parentWindow: NSWindow? = nil) {
        showConfirmationAlert(
            title: "Log Out",
            message: "Are you sure you want to log out the current user session?",
            actionButtonTitle: "Log Out",
            parentWindow: parentWindow
        ) {
            let script = "tell application \"System Events\" to log out"
            self.executeAppleScript(script)
        }
    }

    public func confirmAndForceQuit(parentWindow: NSWindow? = nil) {
        showConfirmationAlert(
            title: "Force Quit Applications",
            message: "Do you want to open the macOS Force Quit window?",
            actionButtonTitle: "Open Force Quit",
            parentWindow: parentWindow
        ) {
            let script = "tell application \"System Events\" to key code 53 using {command down, option down}"
            self.executeAppleScript(script)
        }
    }

    public func confirmAndRunCommand(_ command: String, parentWindow: NSWindow? = nil, completion: @escaping (Bool) -> Void) {
        showConfirmationAlert(
            title: "Run Command",
            message: "Are you sure you want to execute shell command:\n\n\(command)",
            actionButtonTitle: "Execute",
            parentWindow: parentWindow
        ) {
            let task = Process()
            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", command]
            do {
                try task.run()
                completion(true)
            } catch {
                self.showErrorAlert(title: "Command Failed", message: error.localizedDescription)
                completion(false)
            }
        }
    }

    // MARK: - Helpers

    private func executeAppleScript(_ script: String) {
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let err = error {
                print("AppleScript execution note: \(err)")
            }
        }
    }

    private func showConfirmationAlert(
        title: String,
        message: String,
        actionButtonTitle: String,
        parentWindow: NSWindow?,
        onConfirm: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: actionButtonTitle)
        let cancelBtn = alert.addButton(withTitle: "Cancel")
        cancelBtn.keyEquivalent = "\u{1b}" // Esc

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            onConfirm()
        }
    }

    public func showErrorAlert(title: String, message: String) {
        // In unit testing / non-interactive environments, avoid blocking modal run loops
        let isTesting = NSClassFromString("XCTestCase") != nil ||
                        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                        ProcessInfo.processInfo.arguments.contains("--test")
        if isTesting {
            print("⚠️ [MacOSLocationsService] Error Alert (suppressed for testing): \(title) - \(message)")
            return
        }
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
