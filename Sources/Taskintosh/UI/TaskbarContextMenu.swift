import TaskintoshKit
import AppKit

public final class TaskbarContextMenu: NSMenu {
    public init(target: AnyObject, autoHideEnabled: Bool) {
        super.init(title: "Taskbar")
        self.autoenablesItems = false

        let showDesktopItem = NSMenuItem(title: "Minimize All Windows", action: #selector(TaskbarView.showDesktopClicked), keyEquivalent: "")
        showDesktopItem.target = target
        addItem(showDesktopItem)

        addItem(NSMenuItem.separator())

        let taskManagerItem = NSMenuItem(title: "Task Manager", action: #selector(TaskbarView.taskManagerClicked), keyEquivalent: "")
        taskManagerItem.target = target
        addItem(taskManagerItem)

        let updateItem = NSMenuItem(title: "Windows Update...", action: #selector(TaskbarView.windowsUpdateClicked), keyEquivalent: "")
        updateItem.target = target
        addItem(updateItem)

        addItem(NSMenuItem.separator())

        let autoHideItem = NSMenuItem(title: "Auto-Hide the Taskbar", action: #selector(TaskbarView.toggleAutoHideClicked), keyEquivalent: "")
        autoHideItem.target = target
        autoHideItem.state = autoHideEnabled ? .on : .off
        addItem(autoHideItem)

        // Taskbar Size Submenu
        let sizeSubmenu = NSMenu(title: "Taskbar Size")
        let activeSizeRaw = UserDefaults.standard.string(forKey: "TaskbarSizePreset") ?? TaskbarSizePreset.normal.rawValue
        for preset in TaskbarSizePreset.allCases {
            let item = NSMenuItem(title: preset.displayName, action: #selector(TaskbarView.setTaskbarSizePresetClicked(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = preset.rawValue
            item.state = (preset.rawValue == activeSizeRaw) ? .on : .off
            sizeSubmenu.addItem(item)
        }
        let sizeMenuItem = NSMenuItem(title: "Taskbar Size", action: nil, keyEquivalent: "")
        sizeMenuItem.submenu = sizeSubmenu
        addItem(sizeMenuItem)

        addItem(NSMenuItem.separator())

        let propertiesItem = NSMenuItem(title: "Properties & Era Manager...", action: #selector(TaskbarView.openEraManagerClicked), keyEquivalent: "")
        propertiesItem.target = target
        addItem(propertiesItem)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
