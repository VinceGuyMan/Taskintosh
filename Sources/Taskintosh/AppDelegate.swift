import AppKit
import Combine
import TaskintoshKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) weak var shared: AppDelegate?

    private var taskbarPanel: TaskbarPanel?
    private var taskbarView: TaskbarView?
    private var autoHideController: AutoHideController?
    private var statusItem: NSStatusItem?
    private var eraManagerWindow: EraManagerWindow?
    private var runDialog: RunDialog?
    private var shutDownDialog: ShutDownDialog?
    private var cancellables = Set<AnyCancellable>()

    public var isAutoHideEnabled: Bool {
        autoHideController?.isEnabled ?? false
    }

    override public init() {
        super.init()
        AppDelegate.shared = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Initialize Engine & Catalog
        _ = RunningAppWatcher.shared
        _ = AppCatalog.shared
        _ = SystemMonitor.shared
        _ = EraManager.shared

        // 2. Setup Taskbar Window
        setupTaskbar()

        // 3. Setup Menu Bar Status Item for easy control
        setupStatusItem()

        // 4. Observe Era Changes
        EraManager.shared.$activeEra
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEra in
                self?.applyEra(newEra)
            }
            .store(in: &cancellables)

        // 5. Observe Screen Changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshTaskbarGeometry()
            }
            .store(in: &cancellables)
    }

    private func setupTaskbar() {
        let screen = DisplayManager.shared.currentScreen
        let era = EraManager.shared.activeEra
        let targetFrame = DisplayManager.shared.frame(
            for: era.layout.defaultEdge,
            height: era.layout.taskbarHeight,
            on: screen
        )

        let panel = TaskbarPanel(contentRect: targetFrame)
        let view = TaskbarView(frame: NSRect(origin: .zero, size: targetFrame.size))
        view.autoresizingMask = [.width, .height]
        panel.contentView = view

        self.taskbarPanel = panel
        self.taskbarView = view

        let autoHide = AutoHideController(panel: panel)
        self.autoHideController = autoHide

        panel.orderFront(nil)
    }

    private func applyEra(_ era: EraPackage) {
        guard let panel = taskbarPanel else { return }
        let screen = DisplayManager.shared.currentScreen
        panel.updateGeometry(era: era, screen: screen)
        taskbarView?.needsDisplay = true
    }

    public func refreshTaskbarGeometry() {
        guard let panel = taskbarPanel else { return }
        let screen = DisplayManager.shared.currentScreen
        let era = EraManager.shared.activeEra
        panel.updateGeometry(era: era, screen: screen)
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = ProceduralIcons.shared.taskintoshIcon(size: 16)
            button.toolTip = "Taskintosh: The wrong taskbar for the right computer"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Taskintosh 95", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let eraManagerItem = NSMenuItem(title: "Era Manager & Properties...", action: #selector(openEraManager), keyEquivalent: "e")
        eraManagerItem.target = self
        menu.addItem(eraManagerItem)

        let toggleTaskbarItem = NSMenuItem(title: "Toggle Taskbar Visibility", action: #selector(toggleTaskbar), keyEquivalent: "t")
        toggleTaskbarItem.target = self
        menu.addItem(toggleTaskbarItem)

        let toggleAutoHideItem = NSMenuItem(title: "Toggle Auto-Hide", action: #selector(toggleAutoHide), keyEquivalent: "h")
        toggleAutoHideItem.target = self
        menu.addItem(toggleAutoHideItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Taskintosh", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
    }

    @objc public func openEraManager() {
        if eraManagerWindow == nil {
            eraManagerWindow = EraManagerWindow()
        }
        eraManagerWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func openRunDialog() {
        if runDialog == nil {
            runDialog = RunDialog()
        }
        runDialog?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func openShutDownDialog() {
        if shutDownDialog == nil {
            shutDownDialog = ShutDownDialog()
        }
        shutDownDialog?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc public func openHelp() {
        let alert = NSAlert()
        alert.messageText = "Taskintosh Help"
        alert.informativeText = "Taskintosh is a native macOS desktop-history playground.\n\n• Click Start to open applications, run commands, or shut down.\n• Click running taskbar buttons to switch to applications or minimize them.\n• Right-click the taskbar to open Activity Monitor, toggle auto-hide, or configure Eras.\n• Right-click a task button to restore, minimize, or close an app."
        alert.runModal()
    }

    @objc public func toggleTaskbar() {
        guard let panel = taskbarPanel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFront(nil)
        }
    }

    @objc public func toggleAutoHide() {
        autoHideController?.toggle()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
