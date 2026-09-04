import AppKit
import TaskintoshKit

public final class StartMenuWindow: NSWindow {
    public static let shared = StartMenuWindow()

    internal private(set) var cascadeWindow: StartCascadeWindow?
    private var cascadeCategory: String?
    private var outsideClickMonitor: Any?
    private var localClickMonitor: Any?
    private var onDismissCallback: (() -> Void)?

    private var currentWin95View: Windows95MenuView?
    private var currentXPView: WindowsXPMenuView?
    private var currentWin7View: Windows7MenuView?
    private var currentWin8View: Windows8MenuView?
    private var currentWin10View: Windows10MenuView?
    private var currentWin11View: Windows11MenuView?

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .popUpMenu
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isOpaque = false
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.backgroundColor = .clear
    }

    override public var canBecomeKey: Bool {
        return true
    }

    override public var canBecomeMain: Bool {
        return true
    }

    public var lastStartButtonScreenRect: NSRect?
    public private(set) var lastDismissalTimestamp: TimeInterval = 0

    public func showAbove(rect: NSRect, onDismiss: (() -> Void)? = nil) {
        let era = EraManager.shared.activeEra
        self.onDismissCallback = onDismiss
        self.lastStartButtonScreenRect = rect
        closeCascade()
        TrayFlyoutWindow.shared.hideFlyout()

        let menuSize = sizeForEra(era)
        let screen = DisplayManager.shared.currentScreen

        var x: CGFloat = rect.minX
        var y: CGFloat = rect.maxY

        if era.theme.startMenuType == .centeredFlyout {
            // Windows 11: Centered horizontally above the Start button
            x = max(10, min(screen.frame.maxX - menuSize.width - 10, rect.midX - menuSize.width / 2.0))
            y = rect.maxY + 10
        } else if era.theme.startMenuType == .tileLauncher {
            // Windows 8: Spacious launcher
            x = max(10, min(screen.frame.maxX - menuSize.width - 10, rect.minX))
            y = rect.maxY + 2
        } else {
            // Standard left-aligned bottom taskbars
            x = max(2, min(screen.frame.maxX - menuSize.width - 2, rect.minX))
            y = rect.maxY + 1
        }

        // If taskbar is on top edge, display menu beneath it
        if era.layout.defaultEdge == .top {
            y = rect.minY - menuSize.height - 2
        }

        self.setFrame(NSRect(x: x, y: y, width: menuSize.width, height: menuSize.height), display: true)
        setupEraView(era: era)
        self.makeKeyAndOrderFront(nil)

        installOutsideClickMonitor()
    }

    /// Canonical Start menu size for each era (using compact baseline form factor).
    public func sizeForEra(_ era: EraPackage) -> NSSize {
        let canonicalSize: NSSize
        switch era.theme.startMenuType {
        case .classicOneColumn:
            canonicalSize = NSSize(width: 202, height: 282)
        case .twoColumnXP:
            canonicalSize = NSSize(width: 334, height: 387)
        case .twoColumnGlass:
            canonicalSize = NSSize(width: 370, height: 422)
        case .tileLauncher, .modernTiles:
            canonicalSize = NSSize(width: 616, height: 414)
        case .hybridMenu:
            canonicalSize = NSSize(width: 546, height: 431)
        case .centeredFlyout:
            canonicalSize = NSSize(width: 493, height: 510)
        default:
            canonicalSize = NSSize(width: 202, height: 282)
        }

        let screen = DisplayManager.shared.currentScreen
        let maxW = screen.visibleFrame.width - 20
        let maxH = screen.visibleFrame.height - 40
        let w = max(200, min(maxW, canonicalSize.width))
        let h = max(260, min(maxH, canonicalSize.height))

        return NSSize(width: w, height: h)
    }

    private func setupEraView(era: EraPackage) {
        currentWin95View = nil
        currentXPView = nil
        currentWin7View = nil
        currentWin8View = nil
        currentWin10View = nil
        currentWin11View = nil

        switch era.theme.startMenuType {
        case .classicOneColumn:
            let view = Windows95MenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            view.onCascadeRequest = { [weak self] cat, itemRect in
                if cat.isEmpty {
                    self?.closeCascade()
                } else {
                    guard let self = self else { return }
                    let origin = NSPoint(x: self.frame.maxX, y: self.frame.minY + itemRect.maxY)
                    self.showCascade(for: cat, at: origin)
                }
            }
            self.contentView = view
            self.currentWin95View = view

        case .twoColumnXP:
            let view = WindowsXPMenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            view.onCascadeRequest = { [weak self] cat, itemRect in
                guard let self = self else { return }
                let origin = NSPoint(x: self.frame.maxX, y: self.frame.minY + itemRect.maxY)
                self.showCascade(for: cat, at: origin)
            }
            self.contentView = view
            self.currentXPView = view

        case .twoColumnGlass:
            let view = Windows7MenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            view.onCascadeRequest = { [weak self] cat, itemRect in
                guard let self = self else { return }
                let origin = NSPoint(x: self.frame.maxX, y: self.frame.minY + itemRect.maxY)
                self.showCascade(for: cat, at: origin)
            }
            self.contentView = view
            self.currentWin7View = view

        case .tileLauncher, .modernTiles:
            let view = Windows8MenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            self.contentView = view
            self.currentWin8View = view

        case .hybridMenu:
            let view = Windows10MenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            self.contentView = view
            self.currentWin10View = view

        case .centeredFlyout:
            let view = Windows11MenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            self.contentView = view
            self.currentWin11View = view

        default:
            let view = Windows95MenuView()
            view.onDismiss = { [weak self] in self?.hideMenu() }
            self.contentView = view
            self.currentWin95View = view
        }
    }

    public func hideMenu() {
        lastDismissalTimestamp = Date().timeIntervalSinceReferenceDate
        removeOutsideClickMonitor()
        closeCascade()
        self.orderOut(nil)
        onDismissCallback?()
        onDismissCallback = nil
    }

    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            guard let self = self, self.isVisible else { return }
            let clickLoc = NSEvent.mouseLocation
            let menuFrame = self.frame
            let cascadeFrame = self.cascadeWindow?.frame ?? .zero

            if !menuFrame.contains(clickLoc) && !cascadeFrame.contains(clickLoc) {
                self.hideMenu()
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return event }
            let clickLoc = NSEvent.mouseLocation
            let menuFrame = self.frame
            let cascadeFrame = self.cascadeWindow?.frame ?? .zero

            // If the user clicks the Start button while the menu is open, toggle it closed and consume the event
            if let startRect = self.lastStartButtonScreenRect, startRect.contains(clickLoc) {
                self.hideMenu()
                return nil
            }

            if !menuFrame.contains(clickLoc) && !cascadeFrame.contains(clickLoc) {
                self.hideMenu()
            }
            return event
        }
    }

    private func removeOutsideClickMonitor() {
        if let m = outsideClickMonitor {
            NSEvent.removeMonitor(m)
            outsideClickMonitor = nil
        }
        if let m = localClickMonitor {
            NSEvent.removeMonitor(m)
            localClickMonitor = nil
        }
    }

    public func showCascade(for item: String, at origin: NSPoint? = nil) {
        if cascadeWindow != nil && cascadeCategory == item {
            closeCascade()
            self.makeKeyAndOrderFront(nil)
            return
        }

        closeCascade()
        let win = StartCascadeWindow(category: item, parentWindow: self, requestedOrigin: origin)
        win.makeKeyAndOrderFront(nil)
        self.cascadeWindow = win
        self.cascadeCategory = item
    }

    public func closeCascade() {
        cascadeWindow?.orderOut(nil)
        cascadeWindow = nil
        cascadeCategory = nil
    }

    override public func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            hideMenu()
            return
        }

        // Delegate to active era view
        if let v = currentWin95View, v.handleKeyDown(event: event) { return }
        if let v = currentXPView, v.handleKeyDown(event: event) { return }
        if let v = currentWin7View, v.handleKeyDown(event: event) { return }
        if let v = currentWin8View, v.handleKeyDown(event: event) { return }
        if let v = currentWin10View, v.handleKeyDown(event: event) { return }
        if let v = currentWin11View, v.handleKeyDown(event: event) { return }

        super.keyDown(with: event)
    }

    override public func resignKey() {
        super.resignKey()
        // Losing key status is expected when the pointer enters a cascade
        // window. The global/local outside-click monitors own dismissal so a
        // submenu remains open while the user moves between its two panels.
    }
}

public final class StartCascadeWindow: NSWindow {
    public init(category: String, parentWindow: NSWindow, requestedOrigin: NSPoint? = nil) {
        let winW: CGFloat = 260
        let screen = DisplayManager.shared.currentScreen
        let parentFrame = parentWindow.frame
        let winH: CGFloat = min(parentFrame.height, screen.visibleFrame.height - 30)

        // Align flush with Start Menu right edge and level with its bottom
        var x = parentFrame.maxX
        let y = parentFrame.minY

        // If not enough room on the right, dock flush on the left
        if x + winW > screen.visibleFrame.maxX - 10 {
            x = max(screen.visibleFrame.minX + 10, parentFrame.minX - winW)
        }

        super.init(
            contentRect: NSRect(x: x, y: y, width: winW, height: winH),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .popUpMenu
        self.isOpaque = false
        self.hasShadow = true
        self.contentView = StartCascadeView(category: category)
    }

    override public var canBecomeKey: Bool {
        return true
    }

    override public func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            StartMenuWindow.shared.closeCascade()
            StartMenuWindow.shared.makeKeyAndOrderFront(nil)
            return
        }
        super.keyDown(with: event)
    }
}

private final class StartCascadeScrollView: NSScrollView {
    let rowHeight: CGFloat = 30

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        DispatchQueue.main.async { [weak self] in
            self?.snapToRow()
        }
    }

    private func snapToRow() {
        guard let documentView = documentView else { return }
        let maxY = max(0, documentView.bounds.height - contentView.bounds.height)
        let currentY = contentView.bounds.origin.y
        let alignedY = min(maxY, max(0, round(currentY / rowHeight) * rowHeight))
        contentView.setBoundsOrigin(NSPoint(x: contentView.bounds.origin.x, y: alignedY))
        reflectScrolledClipView(contentView)
    }
}

public final class StartCascadeView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private let tableView = NSTableView()
    private let scrollView = StartCascadeScrollView()
    private let category: String
    private let rowHeight: CGFloat = 30

    public struct CascadeRow {
        let title: String
        let subtitle: String?
        let icon: NSImage
        let action: () -> Void
    }

    private var rows: [CascadeRow] = []

    public init(category: String) {
        self.category = category
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 340))
        setupRows()

        let era = EraManager.shared.activeEra
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CascadeCol"))
        col.width = max(0, bounds.width - 24)
        tableView.addTableColumn(col)
        tableView.headerView = nil
        tableView.rowHeight = rowHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = era.theme.surfaceColor
        scrollView.documentView = tableView
        self.addSubview(scrollView)
        layoutScrollView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        layoutScrollView()
    }

    private func layoutScrollView() {
        let availableHeight = max(0, bounds.height - 6)
        let alignedHeight = floor(availableHeight / rowHeight) * rowHeight
        scrollView.frame = NSRect(
            x: 3,
            y: 3,
            width: max(0, bounds.width - 6),
            height: alignedHeight
        )
        if let column = tableView.tableColumns.first {
            column.width = max(0, scrollView.contentSize.width - 24)
        }
    }

    private func setupRows() {
        let locations = MacOSLocationsService.shared
        let icons = ProceduralIcons.shared
        let era = EraManager.shared.activeEra

        switch category {
        case "Programs":
            // Accessories submenu items first, then installed apps
            rows.append(CascadeRow(title: "Terminal", subtitle: "Command Line", icon: icons.icon(for: .terminal, era: era, size: 20)) {
                locations.openTerminal()
            })
            rows.append(CascadeRow(title: "Activity Monitor", subtitle: "Task Manager", icon: icons.icon(for: .terminal, era: era, size: 20)) {
                locations.openActivityMonitor()
            })
            rows.append(CascadeRow(title: "Calculator", subtitle: "Accessories", icon: icons.icon(for: .programs, era: era, size: 20)) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calculator.app"))
            })
            rows.append(CascadeRow(title: "TextEdit", subtitle: "Word Processor", icon: icons.icon(for: .documents, era: era, size: 20)) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/TextEdit.app"))
            })
            for app in AppCatalog.shared.installedApps {
                rows.append(CascadeRow(title: app.name, subtitle: app.category, icon: app.icon) {
                    AppCatalog.shared.launch(app)
                })
            }

        case "Documents":
            rows.append(CascadeRow(title: "My Documents", subtitle: "~/Documents", icon: icons.icon(for: .documents, era: era, size: 20)) {
                locations.openURL(locations.documentsURL)
            })
            rows.append(CascadeRow(title: "Desktop", subtitle: "~/Desktop", icon: icons.icon(for: .folder, era: era, size: 20)) {
                locations.openURL(locations.desktopURL)
            })
            rows.append(CascadeRow(title: "Downloads", subtitle: "~/Downloads", icon: icons.icon(for: .documents, era: era, size: 20)) {
                locations.openURL(locations.downloadsURL)
            })
            rows.append(CascadeRow(title: "Screenshots", subtitle: "Screenshots Folder", icon: icons.icon(for: .pictures, era: era, size: 20)) {
                locations.openURL(locations.screenshotsURL)
            })
            for doc in locations.recentDocumentURLs() {
                rows.append(CascadeRow(title: doc.lastPathComponent, subtitle: doc.deletingLastPathComponent().lastPathComponent, icon: icons.icon(for: .file, era: era, size: 20)) {
                    locations.openURL(doc)
                })
            }

        case "Locations":
            rows.append(CascadeRow(title: "User Library", subtitle: "~/Library (Personal App Data)", icon: icons.icon(for: .folder, era: era, size: 20)) {
                locations.openURL(locations.userLibraryURL)
            })
            rows.append(CascadeRow(title: "System Library", subtitle: "/Library (System Resources)", icon: icons.icon(for: .folder, era: era, size: 20)) {
                locations.openURL(locations.systemLibraryURL)
            })
            if let icloud = locations.iCloudDriveURL {
                rows.append(CascadeRow(title: "iCloud Drive", subtitle: "Cloud Documents", icon: icons.icon(for: .folder, era: era, size: 20)) {
                    locations.openURL(icloud)
                })
            }
            for vol in locations.externalVolumes() {
                rows.append(CascadeRow(title: vol.name, subtitle: vol.isRemovable ? "Removable Drive" : "Mounted Volume", icon: icons.icon(for: .myComputer, era: era, size: 20)) {
                    locations.openURL(vol.url)
                })
            }
            rows.append(CascadeRow(title: "Open Folder...", subtitle: "Choose directory", icon: icons.icon(for: .openFolder, era: era, size: 20)) {
                locations.openFolderDialog { chosen in
                    if let u = chosen { locations.openURL(u) }
                }
            })

        case "Settings":
            rows.append(CascadeRow(title: "Control Panel", subtitle: "macOS System Settings", icon: icons.icon(for: .controlPanel, era: era, size: 20)) {
                locations.openSystemSettings()
            })
            rows.append(CascadeRow(title: "Accessibility", subtitle: "Universal Access", icon: icons.icon(for: .accessibility, era: era, size: 20)) {
                locations.openAccessibilitySettings()
            })
            rows.append(CascadeRow(title: "Taskbar & Start Menu...", subtitle: "Change Era & Settings", icon: icons.icon(for: .eraManager, era: era, size: 20)) {
                AppDelegate.shared?.openEraManager()
            })
            rows.append(CascadeRow(title: "Printers", subtitle: "Printers & Scanners", icon: icons.icon(for: .settings, era: era, size: 20)) {
                locations.openSystemSettings()
            })

        case "Find":
            rows.append(CascadeRow(title: "Files or Folders...", subtitle: "Search by Name and Location", icon: icons.icon(for: .search, era: era, size: 20)) {
                Win95FindDialog.shared.showDialog()
            })
            rows.append(CascadeRow(title: "Computer...", subtitle: "Mounted Volumes & Disks", icon: icons.icon(for: .myComputer, era: era, size: 20)) {
                locations.openURL(URL(fileURLWithPath: "/Volumes"))
            })
            rows.append(CascadeRow(title: "Go to Path...", subtitle: "Direct Path Navigation", icon: icons.icon(for: .goToPath, era: era, size: 20)) {
                AppDelegate.shared?.openGoToPathDialog()
            })

        default:
            rows.append(CascadeRow(title: "No items available", subtitle: nil, icon: ProceduralIcons.shared.helpIcon()) {})
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = EraManager.shared.activeEra.theme
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else { return nil }
        let item = rows[row]

        let cell = NSView(frame: NSRect(x: 0, y: 0, width: max(0, bounds.width - 24), height: rowHeight))
        let imgView = NSImageView(frame: NSRect(x: 4, y: 6, width: 18, height: 18))
        imgView.image = item.icon
        cell.addSubview(imgView)

        let label = NSTextField(labelWithString: item.title)
        label.frame = NSRect(x: 28, y: 6, width: max(0, bounds.width - 56), height: 18)
        label.font = NSFont.systemFont(ofSize: 11)
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        cell.addSubview(label)

        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 && row < rows.count else { return }
        let item = rows[row]
        StartMenuWindow.shared.hideMenu()
        item.action()
    }
}
