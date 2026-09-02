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
        guard let app = item.runningApp ?? NSRunningApplication(processIdentifier: item.pid) else {
            refreshRunningApps()
            return
        }

        let isCurrentFront = (app.processIdentifier == frontmostPID)

        if isCurrentFront {
            if behavior == .minimize {
                // Hide application to mimic minimizing to taskbar
                app.hide()
            }
        } else {
            if app.isHidden {
                app.unhide()
            }
            app.activate(options: [.activateIgnoringOtherApps])
        }
        refreshRunningApps()
    }

    /// Minimizes/hides all running applications (Show Desktop).
    public func minimizeAllWindows() {
        for item in taskItems {
            item.runningApp?.hide()
        }
        refreshRunningApps()
    }
}
