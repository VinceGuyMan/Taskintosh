import AppKit
import TaskintoshKit

public final class StartMenuWindow: NSWindow {
    public static let shared = StartMenuWindow()

    private var cascadeWindow: NSWindow?

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 230, height: 280),
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

        let view = StartMenuView()
        self.contentView = view
    }

    public func showAbove(rect: NSRect) {
        let era = EraManager.shared.activeEra
        let menuWidth: CGFloat = 240
        let menuHeight: CGFloat = 290

        let x = rect.minX
        let y = rect.maxY

        self.setFrame(NSRect(x: x, y: y, width: menuWidth, height: menuHeight), display: true)
        (self.contentView as? StartMenuView)?.setupLayout(era: era)
        self.makeKeyAndOrderFront(nil)
    }

    public func hideMenu() {
        closeCascade()
        self.orderOut(nil)
    }

    public func showCascade(for item: String, at origin: NSPoint) {
        closeCascade()

        let win = NSWindow(
            contentRect: NSRect(x: origin.x, y: origin.y - 200, width: 240, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .popUpMenu
        win.isOpaque = false
        win.hasShadow = true

        let view = StartCascadeView(category: item)
        win.contentView = view
        win.makeKeyAndOrderFront(nil)
        self.cascadeWindow = win
    }

    public func closeCascade() {
        cascadeWindow?.orderOut(nil)
        cascadeWindow = nil
    }

    override public func resignKey() {
        super.resignKey()
        // If clicking outside, close the menu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.cascadeWindow?.isKeyWindow != true {
                self?.hideMenu()
            }
        }
    }
}

public final class StartMenuView: NSView {
    private var era: EraPackage = EraManager.shared.activeEra
    private var trackingArea: NSTrackingArea?
    private var hoveredIndex: Int? = nil

    private struct MenuItemData {
        let title: String
        let icon: NSImage
        let hasSubmenu: Bool
        let action: () -> Void
    }

    private var items: [MenuItemData] = []

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayout(era: EraManager.shared.activeEra)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setupLayout(era: EraPackage) {
        self.era = era

        self.items = [
            MenuItemData(title: "Programs", icon: ProceduralIcons.shared.programsIcon(), hasSubmenu: true) {
                // Open cascade programs
            },
            MenuItemData(title: "Documents", icon: ProceduralIcons.shared.documentsIcon(), hasSubmenu: true) {
                NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"))
            },
            MenuItemData(title: "Settings", icon: ProceduralIcons.shared.settingsIcon(), hasSubmenu: true) {
                AppDelegate.shared?.openEraManager()
            },
            MenuItemData(title: "Find", icon: ProceduralIcons.shared.findIcon(), hasSubmenu: false) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"))
            },
            MenuItemData(title: "Help", icon: ProceduralIcons.shared.helpIcon(), hasSubmenu: false) {
                AppDelegate.shared?.openHelp()
            },
            MenuItemData(title: "Run...", icon: ProceduralIcons.shared.runIcon(), hasSubmenu: false) {
                AppDelegate.shared?.openRunDialog()
            },
            MenuItemData(title: "Shut Down...", icon: ProceduralIcons.shared.shutDownIcon(), hasSubmenu: false) {
                AppDelegate.shared?.openShutDownDialog()
            }
        ]
        self.needsDisplay = true
    }

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let theme = era.theme

        // 1. Background
        theme.surfaceColor.setFill()
        bounds.fill()

        // 2. 3D Raised Bevel Border
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        // 3. Left vertical branding banner (28px wide)
        let bannerRect = NSRect(x: 2, y: 2, width: 26, height: bounds.height - 4)
        drawBanner(in: bannerRect, theme: theme)

        // 4. Draw Menu Items
        let menuX: CGFloat = 30
        let itemHeight: CGFloat = 34
        let startY = bounds.height - 4 - itemHeight

        for (index, item) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)

            // Etched separator before "Shut Down..."
            if index == items.count - 1 {
                let sepRect = NSRect(x: menuX + 2, y: itemRect.maxY + 2, width: itemRect.width - 4, height: 2)
                theme.shadowColor.setFill()
                NSRect(x: sepRect.minX, y: sepRect.minY + 1, width: sepRect.width, height: 1).fill()
                theme.lightHighlightColor.setFill()
                NSRect(x: sepRect.minX, y: sepRect.minY, width: sepRect.width, height: 1).fill()
            }

            let isHovered = (hoveredIndex == index)

            if isHovered {
                theme.accentColor.setFill()
                itemRect.fill()
            }

            // Draw Icon
            item.icon.draw(in: NSRect(x: itemRect.minX + 6, y: itemRect.midY - 11, width: 22, height: 22))

            // Draw Title
            let font = theme.font(size: 12)
            let textColor = isHovered ? NSColor.white : theme.textColor
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
            let attrStr = NSAttributedString(string: item.title, attributes: attrs)
            attrStr.draw(at: NSPoint(x: itemRect.minX + 36, y: itemRect.midY - 7))

            // Submenu Arrow
            if item.hasSubmenu {
                let arrowAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: textColor]
                let arrowStr = NSAttributedString(string: "►", attributes: arrowAttrs)
                arrowStr.draw(at: NSPoint(x: itemRect.maxX - 16, y: itemRect.midY - 6))
            }
        }
    }

    private func drawBanner(in rect: NSRect, theme: EraVisualTheme) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Gradient from navy to cyan/teal
        let colors = [theme.bannerStartColor.cgColor, theme.bannerEndColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            context.saveGState()
            context.clip(to: rect)
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: rect.minY),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
            context.restoreGState()
        }

        // Draw rotated text "Taskintosh 95"
        context.saveGState()
        context.translateBy(x: rect.minX + 18, y: rect.minY + 12)
        context.rotate(by: .pi / 2.0)

        let bannerFont = NSFont.boldSystemFont(ofSize: 14)
        let bannerAttrs: [NSAttributedString.Key: Any] = [
            .font: bannerFont,
            .foregroundColor: NSColor.white
        ]
        let bannerStr = NSAttributedString(string: theme.bannerText, attributes: bannerAttrs)
        bannerStr.draw(at: NSPoint(x: 0, y: 0))
        context.restoreGState()
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let menuX: CGFloat = 30
        let itemHeight: CGFloat = 34
        let startY = bounds.height - 4 - itemHeight

        var foundIndex: Int? = nil
        for (index, _) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)
            if itemRect.contains(loc) {
                foundIndex = index
                break
            }
        }

        if foundIndex != hoveredIndex {
            hoveredIndex = foundIndex
            needsDisplay = true

            if let idx = foundIndex {
                let item = items[idx]
                if item.hasSubmenu && item.title == "Programs" {
                    let winOrigin = window?.frame.origin ?? .zero
                    let cascadeOrigin = NSPoint(x: winOrigin.x + bounds.width, y: winOrigin.y + bounds.height - 10)
                    StartMenuWindow.shared.showCascade(for: item.title, at: cascadeOrigin)
                } else {
                    StartMenuWindow.shared.closeCascade()
                }
            }
        }
    }

    override public func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
        needsDisplay = true
    }

    override public func mouseUp(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let menuX: CGFloat = 30
        let itemHeight: CGFloat = 34
        let startY = bounds.height - 4 - itemHeight

        for (index, item) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)
            if itemRect.contains(loc) {
                StartMenuWindow.shared.hideMenu()
                item.action()
                return
            }
        }
    }
}

public final class StartCascadeView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private let tableView = NSTableView()
    private let category: String
    private var apps: [CatalogApp] = []

    public init(category: String) {
        self.category = category
        super.init(frame: NSRect(x: 0, y: 0, width: 240, height: 320))

        let era = EraManager.shared.activeEra
        self.apps = AppCatalog.shared.installedApps

        let scroll = NSScrollView(frame: NSRect(x: 3, y: 3, width: 234, height: 314))
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AppCol"))
        col.width = 210
        tableView.addTableColumn(col)
        tableView.headerView = nil
        tableView.rowHeight = 24
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = era.theme.surfaceColor
        scroll.documentView = tableView
        self.addSubview(scroll)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = EraManager.shared.activeEra.theme
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return apps.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < apps.count else { return nil }
        let app = apps[row]

        let cell = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        let imgView = NSImageView(frame: NSRect(x: 4, y: 4, width: 16, height: 16))
        imgView.image = app.icon
        cell.addSubview(imgView)

        let label = NSTextField(labelWithString: app.name)
        label.frame = NSRect(x: 26, y: 4, width: 190, height: 16)
        label.font = NSFont.systemFont(ofSize: 11)
        cell.addSubview(label)

        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 && row < apps.count else { return }
        let app = apps[row]
        StartMenuWindow.shared.hideMenu()
        AppCatalog.shared.launch(app)
    }
}
