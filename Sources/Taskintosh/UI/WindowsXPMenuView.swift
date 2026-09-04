import AppKit
import TaskintoshKit

public final class WindowsXPMenuView: NSView {
    public var onDismiss: (() -> Void)?
    public var onCascadeRequest: ((String, NSRect) -> Void)?

    private var selectedColumn: Int = 0 // 0: Left, 1: Right, 2: Bottom
    private var leftIndex: Int = 0
    private var rightIndex: Int = 0

    private var hoveredColumn: Int? = nil
    private var hoveredIndex: Int? = nil
    private var hoveredBottomBtn: Int? = nil // 0: Log Off, 1: Turn Off
    private var trackingArea: NSTrackingArea?

    // Drag-and-drop state for pinned items
    private var dragStartIndex: Int? = nil
    private var dragCurrentTargetIndex: Int? = nil
    private var isDragging: Bool = false
    private var dragMouseDownPoint: NSPoint? = nil

    public struct XPItem {
        public let id: String
        public let title: String
        public let subtitle: String?
        public let icon: NSImage
        public let isBold: Bool
        public let hasSubmenu: Bool
        public let action: () -> Void

        public init(
            id: String = UUID().uuidString,
            title: String,
            subtitle: String? = nil,
            icon: NSImage,
            isBold: Bool = false,
            hasSubmenu: Bool = false,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.isBold = isBold
            self.hasSubmenu = hasSubmenu
            self.action = action
        }
    }

    public private(set) var leftItems: [XPItem] = []
    public private(set) var rightItems: [XPItem] = []

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 384, height: 450))
        setupItems()
    }

    required init?(coder: NSCoder) { fatalError() }

    public func setupItems() {
        let locations = MacOSLocationsService.shared
        let icons = ProceduralIcons.shared
        let eraType = StartMenuType.twoColumnXP

        let pinned = PinnedProgramsManager.shared.pinnedPrograms(for: "org.taskintosh.era.windowsxp")
        var items: [XPItem] = []
        for (idx, p) in pinned.enumerated() {
            let isBold = idx < 2
            let sz: CGFloat = idx < 2 ? 30 : 24
            let icon: NSImage
            switch p.iconType {
            case "internet": icon = icons.icon(for: .internet, eraType: eraType, size: sz)
            case "email": icon = icons.icon(for: .email, eraType: eraType, size: sz)
            case "settings": icon = icons.icon(for: .settings, eraType: eraType, size: sz)
            case "terminal": icon = icons.icon(for: .terminal, eraType: eraType, size: sz)
            case "programs": icon = icons.icon(for: .programs, eraType: eraType, size: sz)
            case "documents": icon = icons.icon(for: .documents, eraType: eraType, size: sz)
            default:
                if let path = p.path {
                    icon = NSWorkspace.shared.icon(forFile: path)
                } else {
                    icon = icons.icon(for: .programs, eraType: eraType, size: sz)
                }
            }

            let action: () -> Void = {
                if p.id == "xp.update" {
                    AppDelegate.shared?.openWindowsUpdate()
                } else if p.id == "xp.internet" {
                    NSWorkspace.shared.open(URL(string: "https://www.google.com")!)
                } else if p.id == "xp.email" {
                    if let url = URL(string: "mailto:") { NSWorkspace.shared.open(url) }
                } else if p.id == "xp.terminal" {
                    locations.openTerminal()
                } else if let path = p.path {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            }

            items.append(XPItem(id: p.id, title: p.title, subtitle: p.subtitle, icon: icon, isBold: isBold, hasSubmenu: false, action: action))
        }

        // All Programs ▶ item stays anchored at the bottom
        items.append(XPItem(id: "xp.allprograms", title: "All Programs ▶", subtitle: nil, icon: icons.icon(for: .programs, eraType: eraType, size: 20), isBold: true, hasSubmenu: true) { [weak self] in
            guard let self = self else { return }
            self.onCascadeRequest?("Programs", NSRect(x: 0, y: 44, width: self.bounds.width / 2.0, height: 32))
        })
        leftItems = items

        // Right column items (macOS system locations & tools)
        rightItems = [
            XPItem(title: "My Documents", subtitle: nil, icon: icons.icon(for: .documents, eraType: eraType, size: 20), isBold: true, hasSubmenu: false) {
                locations.openURL(locations.documentsURL)
            },
            XPItem(title: "My Recent Documents", subtitle: nil, icon: icons.icon(for: .recentDocuments, eraType: eraType, size: 20), isBold: true, hasSubmenu: true) { [weak self] in
                guard let self = self else { return }
                self.onCascadeRequest?("Documents", NSRect(x: self.bounds.width / 2.0, y: self.bounds.height - 110, width: self.bounds.width / 2.0, height: 26))
            },
            XPItem(title: "My Pictures", subtitle: nil, icon: icons.icon(for: .pictures, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                locations.openURL(locations.picturesURL)
            },
            XPItem(title: "My Music", subtitle: nil, icon: icons.icon(for: .music, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                locations.openURL(locations.homeURL.appendingPathComponent("Music"))
            },
            XPItem(title: "My Computer", subtitle: nil, icon: icons.icon(for: .myComputer, eraType: eraType, size: 20), isBold: true, hasSubmenu: false) {
                locations.openURL(URL(fileURLWithPath: "/Volumes"))
            },
            XPItem(title: "Control Panel", subtitle: nil, icon: icons.icon(for: .controlPanel, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                locations.openSystemSettings()
            },
            XPItem(title: "Set Program Access", subtitle: nil, icon: icons.icon(for: .eraManager, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                AppDelegate.shared?.openEraManager()
            },
            XPItem(title: "Printers and Faxes", subtitle: nil, icon: icons.icon(for: .settings, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                locations.openSystemSettings()
            },
            XPItem(title: "Help and Support", subtitle: nil, icon: icons.icon(for: .help, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                AppDelegate.shared?.openHelp()
            },
            XPItem(title: "Search", subtitle: nil, icon: icons.icon(for: .search, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                Win95FindDialog.shared.showDialog()
            },
            XPItem(title: "Run...", subtitle: nil, icon: icons.icon(for: .run, eraType: eraType, size: 20), isBold: false, hasSubmenu: false) {
                AppDelegate.shared?.openRunDialog()
            }
        ]
        self.needsDisplay = true
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateTrackingAreas()
    }

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        let area = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let colW = (bounds.width - 6) / 2.0
        let leftColRect = NSRect(x: 3, y: 44, width: colW, height: bounds.height - 54 - 44)
        let rightColRect = NSRect(x: 3 + colW, y: 44, width: colW, height: bounds.height - 54 - 44)
        let bottomRect = NSRect(x: 2, y: 2, width: bounds.width - 4, height: 42)

        if bottomRect.contains(loc) {
            let btn = loc.x < bottomRect.midX ? 0 : 1
            if hoveredColumn != 2 || hoveredBottomBtn != btn {
                hoveredColumn = 2
                hoveredBottomBtn = btn
                hoveredIndex = nil
                needsDisplay = true
            }
            return
        }

        if leftColRect.contains(loc) {
            let itemH: CGFloat = leftColRect.height / CGFloat(leftItems.count)
            let idx = Int((leftColRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < leftItems.count {
                if hoveredColumn != 0 || hoveredIndex != idx {
                    hoveredColumn = 0
                    hoveredIndex = idx
                    hoveredBottomBtn = nil
                    needsDisplay = true
                }
                return
            }
        }

        if rightColRect.contains(loc) {
            let itemH: CGFloat = rightColRect.height / CGFloat(rightItems.count)
            let idx = Int((rightColRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < rightItems.count {
                if hoveredColumn != 1 || hoveredIndex != idx {
                    hoveredColumn = 1
                    hoveredIndex = idx
                    hoveredBottomBtn = nil
                    needsDisplay = true
                    if rightItems[idx].hasSubmenu {
                        rightItems[idx].action()
                    } else {
                        StartMenuWindow.shared.closeCascade()
                    }
                }
                return
            }
        }

        if hoveredColumn != nil || hoveredIndex != nil || hoveredBottomBtn != nil {
            hoveredColumn = nil
            hoveredIndex = nil
            hoveredBottomBtn = nil
            needsDisplay = true
        }
    }

    override public func mouseExited(with event: NSEvent) {
        if hoveredColumn != nil || hoveredIndex != nil || hoveredBottomBtn != nil {
            hoveredColumn = nil
            hoveredIndex = nil
            hoveredBottomBtn = nil
            needsDisplay = true
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Outer border & background
        let path = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        NSColor(srgbRed: 0.15, green: 0.38, blue: 0.85, alpha: 1.0).setFill()
        path.fill()

        // 1. Header (User area)
        let headerRect = NSRect(x: 2, y: bounds.height - 52, width: bounds.width - 4, height: 50)
        let headerGrad = NSGradient(
            starting: NSColor(srgbRed: 0.05, green: 0.35, blue: 0.85, alpha: 1.0),
            ending: NSColor(srgbRed: 0.18, green: 0.55, blue: 0.98, alpha: 1.0)
        )
        headerGrad?.draw(in: headerRect, angle: 90)

        // User avatar box
        let avatarRect = NSRect(x: 10, y: headerRect.midY - 18, width: 36, height: 36)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: avatarRect, xRadius: 4, yRadius: 4).fill()
        let chessEmblem = ProceduralIcons.shared.lunaStartEmblem(size: 28)
        chessEmblem.draw(in: avatarRect.insetBy(dx: 4, dy: 4))

        let fullName = NSFullUserName().isEmpty ? NSUserName() : NSFullUserName()
        let userStr = StartMenuText.fitted(fullName, font: NSFont.boldSystemFont(ofSize: 13), color: .white, maxWidth: bounds.width - 66)
        userStr.draw(at: NSPoint(x: 54, y: headerRect.midY - 8))

        // 2. Left Column (White pane)
        let colW = (bounds.width - 6) / 2.0
        let leftRect = NSRect(x: 3, y: 44, width: colW, height: bounds.height - 52 - 44)
        NSColor.white.setFill()
        leftRect.fill()

        let leftItemH: CGFloat = leftRect.height / CGFloat(leftItems.count)
        for (index, item) in leftItems.enumerated() {
            let itemY = leftRect.maxY - CGFloat(index + 1) * leftItemH
            let itemRect = NSRect(x: leftRect.minX, y: itemY, width: leftRect.width, height: leftItemH)

            let isHovered = (hoveredColumn == 0 && hoveredIndex == index)
            let isSelected = (selectedColumn == 0 && leftIndex == index)
            if isHovered || isSelected {
                NSColor(srgbRed: 0.18, green: 0.45, blue: 0.92, alpha: 1.0).setFill()
                itemRect.fill()
            }

            // Insertion drop indicator during drag
            if isDragging && dragCurrentTargetIndex == index {
                NSColor(srgbRed: 0.05, green: 0.35, blue: 0.85, alpha: 1.0).setFill()
                NSRect(x: leftRect.minX + 4, y: itemRect.maxY - 1.5, width: leftRect.width - 8, height: 3).fill()
            }

            // Separator after Internet/Email
            if index == 2 || index == leftItems.count - 1 {
                NSColor(white: 0.85, alpha: 1.0).setFill()
                NSRect(x: leftRect.minX + 8, y: itemRect.maxY - 1, width: leftRect.width - 16, height: 1).fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 7, y: itemRect.midY - 13, width: 26, height: 26))

            let titleColor = (isHovered || isSelected) ? NSColor.white : NSColor.black
            let titleFont = item.isBold ? NSFont.boldSystemFont(ofSize: 11.5) : NSFont.systemFont(ofSize: 11.5)
            let titleStr = StartMenuText.fitted(item.title, font: titleFont, color: titleColor, maxWidth: itemRect.maxX - (itemRect.minX + 38) - 6)

            if let sub = item.subtitle {
                titleStr.draw(at: NSPoint(x: itemRect.minX + 38, y: itemRect.midY - 4))
                let subColor = (isHovered || isSelected) ? NSColor.white.withAlphaComponent(0.8) : NSColor.gray
                let subStr = StartMenuText.fitted(sub, font: NSFont.systemFont(ofSize: 9), color: subColor, maxWidth: itemRect.maxX - (itemRect.minX + 38) - 6)
                subStr.draw(at: NSPoint(x: itemRect.minX + 38, y: itemRect.midY - 16))
            } else {
                titleStr.draw(at: NSPoint(x: itemRect.minX + 38, y: itemRect.midY - 7))
            }
        }

        // 3. Right Column (Soft Luna Blue)
        let rightRect = NSRect(x: 3 + colW, y: 44, width: colW, height: bounds.height - 52 - 44)
        NSColor(srgbRed: 0.82, green: 0.89, blue: 0.98, alpha: 1.0).setFill()
        rightRect.fill()

        let rightItemH: CGFloat = rightRect.height / CGFloat(rightItems.count)
        for (index, item) in rightItems.enumerated() {
            let itemY = rightRect.maxY - CGFloat(index + 1) * rightItemH
            let itemRect = NSRect(x: rightRect.minX, y: itemY, width: rightRect.width, height: rightItemH)

            let isHovered = (hoveredColumn == 1 && hoveredIndex == index)
            let isSelected = (selectedColumn == 1 && rightIndex == index)
            if isSelected {
                NSColor(srgbRed: 0.18, green: 0.45, blue: 0.92, alpha: 1.0).setFill()
                itemRect.fill()
            } else if isHovered {
                // Authentic Luna soft hover plate
                let hoverPlate = itemRect.insetBy(dx: 2, dy: 1)
                NSColor(srgbRed: 0.74, green: 0.83, blue: 0.96, alpha: 1.0).setFill()
                NSBezierPath(roundedRect: hoverPlate, xRadius: 2, yRadius: 2).fill()
                NSColor(srgbRed: 0.48, green: 0.62, blue: 0.82, alpha: 1.0).setStroke()
                let border = NSBezierPath(roundedRect: hoverPlate.insetBy(dx: 0.5, dy: 0.5), xRadius: 2, yRadius: 2)
                border.lineWidth = 1
                border.stroke()
            }

            // Divider after My Computer and after Printers
            if index == 5 || index == 8 {
                NSColor(srgbRed: 0.65, green: 0.75, blue: 0.9, alpha: 1.0).setFill()
                NSRect(x: rightRect.minX + 8, y: itemRect.maxY - 1, width: rightRect.width - 16, height: 1).fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 5, y: itemRect.midY - 11, width: 22, height: 22))

            let titleColor = isSelected ? NSColor.white : NSColor(srgbRed: 0.05, green: 0.15, blue: 0.4, alpha: 1.0)
            let titleFont = item.isBold ? NSFont.boldSystemFont(ofSize: 11) : NSFont.systemFont(ofSize: 11)
            let titleStr = StartMenuText.fitted(item.title, font: titleFont, color: titleColor, maxWidth: itemRect.maxX - (itemRect.minX + 30) - (item.hasSubmenu ? 24 : 6))
            titleStr.draw(at: NSPoint(x: itemRect.minX + 30, y: itemRect.midY - 7))

            if item.hasSubmenu {
                let arrowAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 8, weight: .bold), .foregroundColor: titleColor]
                NSAttributedString(string: "▶", attributes: arrowAttrs).draw(at: NSPoint(x: itemRect.maxX - 14, y: itemRect.midY - 6))
            }
        }

        // 4. Bottom Footer (Luna Vibrant Blue)
        let bottomRect = NSRect(x: 2, y: 2, width: bounds.width - 4, height: 42)
        let bottomGrad = NSGradient(
            starting: NSColor(srgbRed: 0.15, green: 0.38, blue: 0.85, alpha: 1.0),
            ending: NSColor(srgbRed: 0.25, green: 0.52, blue: 0.95, alpha: 1.0)
        )
        bottomGrad?.draw(in: bottomRect, angle: 90)

        // Log Off button
        let logOffRect = NSRect(x: 12, y: 6, width: 140, height: 32)
        if hoveredColumn == 2 && hoveredBottomBtn == 0 {
            NSColor.white.withAlphaComponent(0.2).setFill()
            NSBezierPath(roundedRect: logOffRect, xRadius: 4, yRadius: 4).fill()
            NSColor.white.withAlphaComponent(0.4).setStroke()
            NSBezierPath(roundedRect: logOffRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4).stroke()
        }
        let keyIcon = ProceduralIcons.shared.icon(for: .logOff, eraType: .twoColumnXP, size: 18)
        keyIcon.draw(in: NSRect(x: 16, y: 13, width: 18, height: 18))
        let logOffAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Log Off", attributes: logOffAttrs).draw(at: NSPoint(x: 38, y: 15))

        // Turn Off Computer button
        let turnOffRect = NSRect(x: bounds.width - 160, y: 6, width: 150, height: 32)
        if hoveredColumn == 2 && hoveredBottomBtn == 1 {
            NSColor.white.withAlphaComponent(0.2).setFill()
            NSBezierPath(roundedRect: turnOffRect, xRadius: 4, yRadius: 4).fill()
            NSColor.white.withAlphaComponent(0.4).setStroke()
            NSBezierPath(roundedRect: turnOffRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4).stroke()
        }
        let powerIcon = ProceduralIcons.shared.icon(for: .shutDown, eraType: .twoColumnXP, size: 18)
        powerIcon.draw(in: NSRect(x: turnOffRect.minX + 4, y: 13, width: 18, height: 18))
        NSAttributedString(string: "Turn Off Computer", attributes: logOffAttrs).draw(at: NSPoint(x: turnOffRect.minX + 26, y: 15))
    }

    override public func rightMouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let colW = (bounds.width - 6) / 2.0
        let leftRect = NSRect(x: 3, y: 44, width: colW, height: bounds.height - 52 - 44)

        if leftRect.contains(loc) {
            let itemH: CGFloat = leftRect.height / CGFloat(leftItems.count)
            let idx = Int((leftRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < leftItems.count - 1 {
                let item = leftItems[idx]
                let menu = NSMenu(title: item.title)

                let openItem = NSMenuItem(title: "Open", action: #selector(contextOpenClicked(_:)), keyEquivalent: "")
                openItem.target = self
                openItem.tag = idx
                menu.addItem(openItem)

                menu.addItem(NSMenuItem.separator())

                let unpinItem = NSMenuItem(title: "Unpin from Start menu", action: #selector(contextUnpinClicked(_:)), keyEquivalent: "")
                unpinItem.target = self
                unpinItem.representedObject = item.id
                menu.addItem(unpinItem)

                if idx > 0 {
                    let moveUpItem = NSMenuItem(title: "Move Up", action: #selector(contextMoveUpClicked(_:)), keyEquivalent: "")
                    moveUpItem.target = self
                    moveUpItem.tag = idx
                    menu.addItem(moveUpItem)
                }

                if idx < leftItems.count - 2 {
                    let moveDownItem = NSMenuItem(title: "Move Down", action: #selector(contextMoveDownClicked(_:)), keyEquivalent: "")
                    moveDownItem.target = self
                    moveDownItem.tag = idx
                    menu.addItem(moveDownItem)
                }

                menu.addItem(NSMenuItem.separator())

                let resetItem = NSMenuItem(title: "Reset Pinned Programs to Default", action: #selector(contextResetClicked), keyEquivalent: "")
                resetItem.target = self
                menu.addItem(resetItem)

                NSMenu.popUpContextMenu(menu, with: event, for: self)
                return
            }
        }
        super.rightMouseDown(with: event)
    }

    @objc private func contextOpenClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        if idx >= 0 && idx < leftItems.count {
            StartMenuWindow.shared.hideMenu()
            leftItems[idx].action()
        }
    }

    @objc private func contextUnpinClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        PinnedProgramsManager.shared.unpin(id: id, in: "org.taskintosh.era.windowsxp")
        setupItems()
        needsDisplay = true
    }

    @objc private func contextMoveUpClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx > 0 else { return }
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: idx - 1, in: "org.taskintosh.era.windowsxp")
        setupItems()
        needsDisplay = true
    }

    @objc private func contextMoveDownClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx < leftItems.count - 2 else { return }
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: idx + 1, in: "org.taskintosh.era.windowsxp")
        setupItems()
        needsDisplay = true
    }

    @objc private func contextResetClicked() {
        PinnedProgramsManager.shared.resetToDefaults(for: "org.taskintosh.era.windowsxp")
        setupItems()
        needsDisplay = true
    }

    override public func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if let start = dragMouseDownPoint, hypot(loc.x - start.x, loc.y - start.y) > 4, dragStartIndex != nil {
            isDragging = true
            let colW = (bounds.width - 6) / 2.0
            let leftRect = NSRect(x: 3, y: 44, width: colW, height: bounds.height - 52 - 44)
            let itemH = leftRect.height / CGFloat(leftItems.count)
            let targetIdx = max(0, min(leftItems.count - 2, Int((leftRect.maxY - loc.y) / itemH)))
            dragCurrentTargetIndex = targetIdx
            needsDisplay = true
        }
    }

    override public func mouseUp(with event: NSEvent) {
        if isDragging {
            if let from = dragStartIndex, let to = dragCurrentTargetIndex, from != to {
                PinnedProgramsManager.shared.reorder(fromIndex: from, toIndex: to, in: "org.taskintosh.era.windowsxp")
                setupItems()
            }
            dragStartIndex = nil
            dragCurrentTargetIndex = nil
            isDragging = false
            dragMouseDownPoint = nil
            needsDisplay = true
            return
        }

        if let from = dragStartIndex, from < leftItems.count {
            let item = leftItems[from]
            dragStartIndex = nil
            dragCurrentTargetIndex = nil
            isDragging = false
            dragMouseDownPoint = nil
            if !item.hasSubmenu {
                StartMenuWindow.shared.hideMenu()
                item.action()
            }
            return
        }

        dragStartIndex = nil
        dragCurrentTargetIndex = nil
        isDragging = false
        dragMouseDownPoint = nil
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let colW = (bounds.width - 6) / 2.0
        let leftRect = NSRect(x: 3, y: 44, width: colW, height: bounds.height - 52 - 44)
        let rightRect = NSRect(x: 3 + colW, y: 44, width: colW, height: bounds.height - 52 - 44)
        let bottomRect = NSRect(x: 2, y: 2, width: bounds.width - 4, height: 42)

        if bottomRect.contains(loc) {
            if loc.x < bottomRect.midX {
                StartMenuWindow.shared.hideMenu()
                MacOSLocationsService.shared.confirmAndLogOut()
            } else {
                StartMenuWindow.shared.hideMenu()
                AppDelegate.shared?.openShutDownDialog()
            }
            return
        }

        if leftRect.contains(loc) {
            let itemH: CGFloat = leftRect.height / CGFloat(leftItems.count)
            let idx = Int((leftRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < leftItems.count {
                leftIndex = idx
                selectedColumn = 0
                dragStartIndex = (idx < leftItems.count - 1) ? idx : nil
                dragMouseDownPoint = loc
                isDragging = false
                needsDisplay = true
                if leftItems[idx].hasSubmenu {
                    leftItems[idx].action()
                }
                return
            }
        }

        if rightRect.contains(loc) {
            let itemH: CGFloat = rightRect.height / CGFloat(rightItems.count)
            let idx = Int((rightRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < rightItems.count {
                rightIndex = idx
                selectedColumn = 1
                needsDisplay = true
                if !rightItems[idx].hasSubmenu {
                    StartMenuWindow.shared.hideMenu()
                }
                rightItems[idx].action()
                return
            }
        }
    }

    public func handleKeyDown(event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // Up Arrow
            if selectedColumn == 0 {
                leftIndex = (leftIndex - 1 + leftItems.count) % leftItems.count
            } else if selectedColumn == 1 {
                rightIndex = (rightIndex - 1 + rightItems.count) % rightItems.count
            }
            needsDisplay = true
            return true
        case 125: // Down Arrow
            if selectedColumn == 0 {
                leftIndex = (leftIndex + 1) % leftItems.count
            } else if selectedColumn == 1 {
                rightIndex = (rightIndex + 1) % rightItems.count
            }
            needsDisplay = true
            return true
        case 123: // Left Arrow
            selectedColumn = 0
            needsDisplay = true
            return true
        case 124: // Right Arrow
            selectedColumn = 1
            needsDisplay = true
            return true
        case 36: // Enter
            if selectedColumn == 0 && leftIndex < leftItems.count {
                let item = leftItems[leftIndex]
                if !item.hasSubmenu { StartMenuWindow.shared.hideMenu() }
                item.action()
                return true
            } else if selectedColumn == 1 && rightIndex < rightItems.count {
                let item = rightItems[rightIndex]
                if !item.hasSubmenu { StartMenuWindow.shared.hideMenu() }
                item.action()
                return true
            }
        default:
            break
        }
        return false
    }
}
