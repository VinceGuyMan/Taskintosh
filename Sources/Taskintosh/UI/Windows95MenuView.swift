import AppKit
import TaskintoshKit

public final class Windows95MenuView: NSView {
    public var onDismiss: (() -> Void)?
    public var onCascadeRequest: ((String, NSRect) -> Void)?

    private var selectedIndex: Int = 0
    private var trackingArea: NSTrackingArea?

    public struct Win95Item {
        public let title: String
        public let icon: NSImage
        public let hasSubmenu: Bool
        public let isSeparatorBefore: Bool
        public let action: () -> Void
    }

    public private(set) var items: [Win95Item] = []

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 216, height: 308))
        setupItems()
    }

    required init?(coder: NSCoder) { fatalError() }

    public func setupItems() {
        let icons = ProceduralIcons.shared
        let eraType = StartMenuType.classicOneColumn
        let userName = NSUserName()

        items = [
            Win95Item(title: "Windows Update...", icon: icons.icon(for: .settings, eraType: eraType, size: 20), hasSubmenu: false, isSeparatorBefore: false) {
                AppDelegate.shared?.openWindowsUpdate()
            },
            Win95Item(title: "Programs", icon: icons.icon(for: .programs, eraType: eraType, size: 20), hasSubmenu: true, isSeparatorBefore: false) { [weak self] in
                self?.openCascade(category: "Programs")
            },
            Win95Item(title: "Documents", icon: icons.icon(for: .documents, eraType: eraType, size: 20), hasSubmenu: true, isSeparatorBefore: false) { [weak self] in
                self?.openCascade(category: "Documents")
            },
            Win95Item(title: "Settings", icon: icons.icon(for: .controlPanel, eraType: eraType, size: 20), hasSubmenu: true, isSeparatorBefore: false) { [weak self] in
                self?.openCascade(category: "Settings")
            },
            Win95Item(title: "Find", icon: icons.icon(for: .search, eraType: eraType, size: 20), hasSubmenu: true, isSeparatorBefore: false) { [weak self] in
                self?.openCascade(category: "Find")
            },
            Win95Item(title: "Help", icon: icons.icon(for: .help, eraType: eraType, size: 20), hasSubmenu: false, isSeparatorBefore: false) {
                AppDelegate.shared?.openHelp()
            },
            Win95Item(title: "Run...", icon: icons.icon(for: .run, eraType: eraType, size: 20), hasSubmenu: false, isSeparatorBefore: false) {
                AppDelegate.shared?.openRunDialog()
            },
            Win95Item(title: "Log Off \(userName)...", icon: icons.icon(for: .logOff, eraType: eraType, size: 20), hasSubmenu: false, isSeparatorBefore: true) {
                MacOSLocationsService.shared.confirmAndLogOut()
            },
            Win95Item(title: "Shut Down...", icon: icons.icon(for: .shutDown, eraType: eraType, size: 20), hasSubmenu: false, isSeparatorBefore: false) {
                AppDelegate.shared?.openShutDownDialog()
            }
        ]
        self.needsDisplay = true
    }

    private func openCascade(category: String) {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        let menuX: CGFloat = 28
        let itemHeight: CGFloat = 32
        let startY = bounds.height - 4 - itemHeight
        let itemRect = NSRect(x: menuX, y: startY - CGFloat(selectedIndex) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)
        onCascadeRequest?(category, itemRect)
    }

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        let area = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let win95Era = EraManager.shared.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" })
        let theme = win95Era?.theme ?? EraManager.shared.activeEra.theme

        // 1. Classic 95 Gray Background & 3D bevel
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        // 2. Left vertical branding banner
        let bannerRect = NSRect(x: 2, y: 2, width: 24, height: bounds.height - 4)
        drawBanner(in: bannerRect, theme: theme)

        // 3. Draw Menu Items
        let menuX: CGFloat = 28
        let itemHeight: CGFloat = 32
        let startY = bounds.height - 4 - itemHeight

        for (index, item) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)

            if item.isSeparatorBefore {
                theme.shadowColor.setFill()
                NSRect(x: menuX + 2, y: itemRect.maxY + 2, width: itemRect.width - 4, height: 1).fill()
                theme.lightHighlightColor.setFill()
                NSRect(x: menuX + 2, y: itemRect.maxY + 1, width: itemRect.width - 4, height: 1).fill()
            }

            let isSelected = (index == selectedIndex)
            if isSelected {
                NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0).setFill()
                itemRect.fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 6, y: itemRect.midY - 10, width: 20, height: 20))

            let font = theme.font(size: 11)
            let textColor = isSelected ? NSColor.white : theme.textColor
            let attrStr = StartMenuText.fitted(item.title, font: font, color: textColor, maxWidth: itemRect.maxX - (itemRect.minX + 32) - (item.hasSubmenu ? 24 : 6))
            attrStr.draw(at: NSPoint(x: itemRect.minX + 32, y: itemRect.midY - 7))

            if item.hasSubmenu {
                let arrowAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: textColor]
                let arrow = NSAttributedString(string: "▶", attributes: arrowAttrs)
                arrow.draw(at: NSPoint(x: itemRect.maxX - 16, y: itemRect.midY - 6))
            }
        }
    }

    private func drawBanner(in rect: NSRect, theme: EraVisualTheme) {
        let grad = NSGradient(
            starting: NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0),
            ending: NSColor(srgbRed: 0.0, green: 0.0, blue: 0.25, alpha: 1.0)
        )
        grad?.draw(in: rect, angle: 90)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()

        let bannerText = "Taskintosh 95"
        let font = NSFont.boldSystemFont(ofSize: 12)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.85, alpha: 1.0)
        ]
        let attrStr = NSAttributedString(string: bannerText, attributes: attrs)

        // Rotate 90 degrees counter-clockwise for vertical text reading upward
        context.translateBy(x: rect.minX + 17, y: rect.minY + 8)
        context.rotate(by: .pi / 2.0)
        attrStr.draw(at: .zero)

        context.restoreGState()
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let menuX: CGFloat = 28
        let itemHeight: CGFloat = 32
        let startY = bounds.height - 4 - itemHeight

        var foundIndex: Int? = nil
        for (index, _) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)
            if itemRect.contains(loc) {
                foundIndex = index
                break
            }
        }

        if let index = foundIndex {
            if selectedIndex != index {
                selectedIndex = index
                needsDisplay = true
                if items[index].hasSubmenu {
                    items[index].action()
                } else {
                    StartMenuWindow.shared.closeCascade()
                }
            }
        }
    }

    override public func rightMouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let menuX: CGFloat = 28
        let itemHeight: CGFloat = 32
        let startY = bounds.height - 4 - itemHeight

        for (index, item) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)
            if itemRect.contains(loc) {
                selectedIndex = index
                needsDisplay = true

                let menu = NSMenu(title: item.title)
                let openItem = NSMenuItem(title: "Open", action: #selector(contextOpenClicked(_:)), keyEquivalent: "")
                openItem.target = self
                openItem.tag = index
                menu.addItem(openItem)

                let propsItem = NSMenuItem(title: "Properties", action: #selector(contextPropsClicked), keyEquivalent: "")
                propsItem.target = self
                menu.addItem(propsItem)

                NSMenu.popUpContextMenu(menu, with: event, for: self)
                return
            }
        }
        super.rightMouseDown(with: event)
    }

    @objc private func contextOpenClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        if idx >= 0 && idx < items.count {
            let item = items[idx]
            if !item.hasSubmenu {
                StartMenuWindow.shared.hideMenu()
            }
            item.action()
        }
    }

    @objc private func contextPropsClicked() {
        StartMenuWindow.shared.hideMenu()
        AppDelegate.shared?.openEraManager()
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let menuX: CGFloat = 28
        let itemHeight: CGFloat = 32
        let startY = bounds.height - 4 - itemHeight

        for (index, item) in items.enumerated() {
            let itemRect = NSRect(x: menuX, y: startY - CGFloat(index) * itemHeight, width: bounds.width - menuX - 3, height: itemHeight)
            if itemRect.contains(loc) {
                selectedIndex = index
                needsDisplay = true
                if !item.hasSubmenu {
                    StartMenuWindow.shared.hideMenu()
                }
                item.action()
                return
            }
        }
    }

    public func handleKeyDown(event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // Up Arrow
            selectedIndex = (selectedIndex - 1 + items.count) % items.count
            needsDisplay = true
            return true
        case 125: // Down Arrow
            selectedIndex = (selectedIndex + 1) % items.count
            needsDisplay = true
            return true
        case 124: // Right Arrow
            if selectedIndex >= 0 && selectedIndex < items.count && items[selectedIndex].hasSubmenu {
                items[selectedIndex].action()
                return true
            }
        case 36: // Enter
            if selectedIndex >= 0 && selectedIndex < items.count {
                let item = items[selectedIndex]
                if !item.hasSubmenu {
                    StartMenuWindow.shared.hideMenu()
                }
                item.action()
                return true
            }
        default:
            break
        }
        return false
    }
}
