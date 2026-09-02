import AppKit
import TaskintoshKit

public final class TaskbarContextMenu: NSMenu {
    public init(autoHideEnabled: Bool, onToggleAutoHide: @escaping () -> Void) {
        super.init(title: "Taskbar")

        let showDesktopItem = NSMenuItem(title: "Minimize All Windows", action: #selector(showDesktopClicked), keyEquivalent: "")
        showDesktopItem.target = self
        addItem(showDesktopItem)

        addItem(NSMenuItem.separator())

        let taskManagerItem = NSMenuItem(title: "Task Manager", action: #selector(taskManagerClicked), keyEquivalent: "")
        taskManagerItem.target = self
        addItem(taskManagerItem)

        addItem(NSMenuItem.separator())

        let autoHideItem = NSMenuItem(title: "Auto-Hide the Taskbar", action: #selector(autoHideClicked), keyEquivalent: "")
        autoHideItem.target = self
        autoHideItem.state = autoHideEnabled ? .on : .off
        addItem(autoHideItem)

        let propertiesItem = NSMenuItem(title: "Properties & Era Manager...", action: #selector(propertiesClicked), keyEquivalent: "")
        propertiesItem.target = self
        addItem(propertiesItem)
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    @objc private func showDesktopClicked() {
        RunningAppWatcher.shared.minimizeAllWindows()
    }

    @objc private func taskManagerClicked() {
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }

    @objc private func autoHideClicked() {
        AppDelegate.shared?.toggleAutoHide()
    }

    @objc private func propertiesClicked() {
        AppDelegate.shared?.openEraManager()
    }
}
