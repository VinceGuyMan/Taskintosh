import AppKit
import Combine

public final class RunningAppWatcher: ObservableObject {
    public static let shared = RunningAppWatcher()

    @Published public private(set) var taskItems: [TaskItem] = []
    @Published public private(set) var frontmostPID: pid_t?

    private var cancellables = Set<AnyCancellable>()
    private let workspace = NSWorkspace.shared

    public init() {
        refreshRunningApps()
        setupNotificationObservers()
    }

    /// Full refresh of all running regular GUI applications.
    public func refreshRunningApps() {
        let frontmost = workspace.frontmostApplication
        self.frontmostPID = frontmost?.processIdentifier
        let selfPID = NSRunningApplication.current.processIdentifier

        let running = workspace.runningApplications.filter { app in
            // Only regular GUI applications, exclude background daemons, agents, and self
            app.activationPolicy == .regular && app.processIdentifier != selfPID
        }

        self.taskItems = running.map { app in
            let isFront = (app.processIdentifier == frontmost?.processIdentifier)
            return TaskItem(
                id: "\(app.bundleIdentifier ?? "app")-\(app.processIdentifier)",
                title: app.localizedName ?? "Application",
                icon: app.icon,
                pid: app.processIdentifier,
                bundleIdentifier: app.bundleIdentifier,
                isActive: isFront,
                isMinimized: app.isHidden,
                windowNumber: nil,
                runningApp: app
            )
        }
    }

    /// Overrides the current task items for testing or snapshot generation.
    public func setTaskItemsForTesting(_ items: [TaskItem]) {
        self.taskItems = items
    }

    private func setupNotificationObservers() {
        let center = workspace.notificationCenter

        let notifications: [NSNotification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didDeactivateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ]

        for notif in notifications {
            center.publisher(for: notif)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.refreshRunningApps()
                }
                .store(in: &cancellables)
        }
    }

    /// Handles a click on a task item.
    /// If inactive, brings to front. If already frontmost, minimizes/hides according to era behavior.
    public func handleTaskItemClick(_ item: TaskItem, behavior: ClickActiveAction = .minimize) {
        guard let app = item.resolveApp() else {
            refreshRunningApps()
            return
        }

        let isCurrentFront = (app.processIdentifier == frontmostPID)

        if isCurrentFront {
            if behavior == .minimize {
                minimizeApp(item)
            }
        } else {
            restoreApp(item)
        }
        refreshRunningApps()
    }

    /// Brings an application to the foreground, unhides it, and unminimizes its windows.
    public func restoreApp(_ item: TaskItem) {
        guard let app = item.resolveApp() else { return }

        // 1. Accessibility API unminimization (if granted)
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success,
           let windows = value as? [AXUIElement] {
            for window in windows {
                AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                // Also raise window to front
                AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            }
        }

        // 2. Unhide if hidden
        if app.isHidden {
            app.unhide()
        }

        // 3. Activate application ignoring other apps
        app.activate(options: [.activateIgnoringOtherApps])

        // 4. Send reopen Apple Event via NSWorkspace to restore minimized windows without requiring Accessibility permissions
        if let bundleURL = app.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            config.addsToRecentItems = false
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
        }

        // 5. AppleScript reopen fallback: macOS Dock invokes 'reopen' on minimized apps
        if let name = app.localizedName {
            DispatchQueue.global(qos: .userInitiated).async {
                let script = """
                tell application id "\(app.bundleIdentifier ?? "")"
                    reopen
                    activate
                end tell
                """
                var error: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&error)
                if error != nil {
                    // Fallback to localized process name in System Events
                    let sysScript = """
                    tell application "System Events"
                        tell process "\(name)"
                            set visible to true
                            set frontmost to true
                            repeat with w in (every window whose value of attribute "AXMinimized" is true)
                                set value of attribute "AXMinimized" of w to false
                            end repeat
                        end tell
                    end tell
                    """
                    NSAppleScript(source: sysScript)?.executeAndReturnError(nil)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.refreshRunningApps()
        }
    }

    /// Minimizes or hides an application.
    public func minimizeApp(_ item: TaskItem) {
        guard let app = item.resolveApp() else { return }

        // If Accessibility is enabled, minimize windows via AXUIElement
        if WindowAccessibilityBridge.shared.isAccessibilityTrusted {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var value: AnyObject?
            if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success,
               let windows = value as? [AXUIElement] {
                for window in windows {
                    AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
                }
            }
        }

        // Primary hide, with fallback if macOS blocks app.hide()
        if !app.hide() {
            if let name = app.localizedName {
                let script = "tell application \"System Events\" to set visible of process \"\(name)\" to false"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.refreshRunningApps()
        }
    }

    /// Terminates/quits an application.
    public func terminateApp(_ item: TaskItem) {
        guard let app = item.resolveApp() else { return }
        app.terminate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.refreshRunningApps()
        }
    }

    /// Minimizes/hides all running applications (Show Desktop).
    public func minimizeAllWindows() {
        for item in taskItems {
            guard let app = item.resolveApp() else { continue }
            if WindowAccessibilityBridge.shared.isAccessibilityTrusted {
                let appRef = AXUIElementCreateApplication(app.processIdentifier)
                var value: AnyObject?
                if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success,
                   let windows = value as? [AXUIElement] {
                    for window in windows {
                        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
                    }
                }
            }
            if !app.hide() {
                if let name = app.localizedName {
                    let script = "tell application \"System Events\" to set visible of process \"\(name)\" to false"
                    NSAppleScript(source: script)?.executeAndReturnError(nil)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.refreshRunningApps()
        }
    }
}
