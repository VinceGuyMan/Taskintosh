import AppKit
import TaskintoshKit

public final class Windows10MenuView: NSView, NSTextFieldDelegate {
    public var onDismiss: (() -> Void)?

    private let searchField = NSTextField()
    private var isSearching = false
    private var searchResults: [StartMenuSearchResult] = []
    private var selectedSection: Int = 1 // 0: Rail, 1: App List, 2: Tiles
    private var selectedIndex: Int = 0
    private var hoveredSection: Int? = nil
    private var hoveredIndex: Int? = nil
    private var trackingArea: NSTrackingArea?

    public var scrollOffsetY: CGFloat = 0
    public private(set) var maxScrollY: CGFloat = 0
    private var tileScrollOffsetY: CGFloat = 0
    private var maxTileScrollY: CGFloat = 0

    // Drag-and-drop state for tiles
    private var dragStartIndex: Int? = nil
    private var dragCurrentTargetIndex: Int? = nil
    private var isDragging: Bool = false
    private var dragMouseDownPoint: NSPoint? = nil

    public struct Win10Tile {
        public let id: String
        public let title: String
        public let icon: NSImage
        public let color: NSColor
        public let isWide: Bool
        public let action: () -> Void

        public init(
            id: String = UUID().uuidString,
            title: String,
            icon: NSImage,
            color: NSColor,
            isWide: Bool = false,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.icon = icon
            self.color = color
            self.isWide = isWide
            self.action = action
        }
    }

    public private(set) var appList: [CatalogApp] = []
    public private(set) var pinnedTiles: [Win10Tile] = []
    private var tileRects: [(tile: Win10Tile, rect: NSRect, index: Int)] = []

    private var tileViewportRect: NSRect {
        let minX = min(bounds.width, max(292, bounds.width - 320))
        return NSRect(
            x: minX,
            y: 8,
            width: max(0, bounds.width - minX),
            height: max(0, bounds.height - 52)
        )
    }

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 620, height: 490))
        setupComponents()
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupComponents() {
        searchField.frame = NSRect(x: 56, y: bounds.height - 40, width: 220, height: 26)
        searchField.placeholderString = "Type here to search"
        searchField.font = NSFont.systemFont(ofSize: 11)
        searchField.delegate = self
        searchField.focusRingType = .none
        addSubview(searchField)
    }

    public func setupContent() {
        let locations = MacOSLocationsService.shared
        AppCatalog.shared.ensureLoadedSynchronously()
        self.appList = AppCatalog.shared.installedApps

        let icons = ProceduralIcons.shared
        let eraType = StartMenuType.hybridMenu

        let pinned = PinnedProgramsManager.shared.pinnedPrograms(for: "org.taskintosh.era.windows10")
        var tiles: [Win10Tile] = []

        for p in pinned {
            let sz: CGFloat = p.isWide ? 26 : 24
            let icon: NSImage
            switch p.iconType {
            case "internet": icon = icons.icon(for: .internet, eraType: eraType, size: sz)
            case "email": icon = icons.icon(for: .email, eraType: eraType, size: sz)
            case "settings": icon = icons.icon(for: .settings, eraType: eraType, size: sz)
            case "terminal": icon = icons.icon(for: .terminal, eraType: eraType, size: sz)
            case "programs": icon = icons.icon(for: .programs, eraType: eraType, size: sz)
            case "documents": icon = icons.icon(for: .documents, eraType: eraType, size: sz)
            case "pictures": icon = icons.icon(for: .pictures, eraType: eraType, size: sz)
            case "myComputer": icon = icons.icon(for: .myComputer, eraType: eraType, size: sz)
            case "eraManager": icon = icons.icon(for: .eraManager, eraType: eraType, size: sz)
            default:
                if let path = p.path {
                    icon = NSWorkspace.shared.icon(forFile: path)
                } else {
                    icon = icons.icon(for: .programs, eraType: eraType, size: sz)
                }
            }

            let color: NSColor
            if let hex = p.colorHex, let c = NSColor(hex: hex) {
                color = c
            } else {
                color = NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0)
            }

            let action: () -> Void = {
                switch p.id {
                case "w10.browser": NSWorkspace.shared.open(URL(string: "https://www.google.com")!)
                case "w10.mail": if let url = URL(string: "mailto:") { NSWorkspace.shared.open(url) }
                case "w10.terminal": locations.openTerminal()
                case "w10.calc": NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calculator.app"))
                case "w10.settings": locations.openSystemSettings()
                case "w10.docs": locations.openURL(locations.documentsURL)
                case "w10.downloads": locations.openURL(locations.downloadsURL)
                case "w10.pictures": locations.openURL(locations.picturesURL)
                case "w10.computer": locations.openURL(URL(fileURLWithPath: "/Volumes"))
                case "w10.era": AppDelegate.shared?.openEraManager()
                case "w10.update": AppDelegate.shared?.openWindowsUpdate()
                default:
                    if let path = p.path {
                        NSWorkspace.shared.open(URL(fileURLWithPath: path))
                    }
                }
            }

            tiles.append(Win10Tile(id: p.id, title: p.title, icon: icon, color: color, isWide: p.isWide, action: action))
        }

        pinnedTiles = tiles
        recomputeScrollBounds()
        recomputeTileLayouts()
        self.needsDisplay = true
    }

    private func recomputeScrollBounds() {
        let listH = bounds.height - 44
        let itemH: CGFloat = 32
        let totalCount = isSearching ? searchResults.count : appList.count
        let totalH = CGFloat(totalCount) * itemH
        maxScrollY = max(0, totalH - listH + 20)
        scrollOffsetY = min(scrollOffsetY, maxScrollY)
    }

    private func recomputeTileLayouts() {
        tileRects.removeAll()
        let tilesX = bounds.width - 320
        let tilesRect = NSRect(x: max(292, tilesX), y: 0, width: 310, height: bounds.height)
        let tileH: CGFloat = 68
        let standardW: CGFloat = 94
        let spacing: CGFloat = 6

        let startX = tilesRect.minX + 8
        let startY = tileViewportRect.maxY - tileH

        var occupied = Array(repeating: Array(repeating: false, count: 8), count: 2)

        for (index, tile) in pinnedTiles.enumerated() {
            let isWide = tile.isWide
            var placed = false

            for r in 0..<8 {
                if placed { break }
                if isWide {
                    if !occupied[0][r] && !occupied[1][r] {
                        occupied[0][r] = true
                        occupied[1][r] = true
                        let x = startX
                        let y = startY - CGFloat(r) * (tileH + spacing)
                        let w = 2 * standardW + spacing
                        let rect = NSRect(x: x, y: y, width: w, height: tileH)
                        tileRects.append((tile: tile, rect: rect, index: index))
                        placed = true
                        break
                    }
                } else {
                    for c in 0..<2 {
                        if !occupied[c][r] {
                            occupied[c][r] = true
                            let x = startX + CGFloat(c) * (standardW + spacing)
                            let y = startY - CGFloat(r) * (tileH + spacing)
                            let rect = NSRect(x: x, y: y, width: standardW, height: tileH)
                            tileRects.append((tile: tile, rect: rect, index: index))
                            placed = true
                            break
                        }
                    }
                }
            }
        }

        let lowestTileY = tileRects.map { $0.rect.minY }.min() ?? tileViewportRect.minY
        maxTileScrollY = max(0, tileViewportRect.minY - lowestTileY)
        tileScrollOffsetY = min(tileScrollOffsetY, maxTileScrollY)
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        searchField.frame = NSRect(x: 56, y: newSize.height - 40, width: 220, height: 26)
        recomputeScrollBounds()
        recomputeTileLayouts()
        updateTrackingAreas()
    }

    public func controlTextDidChange(_ obj: Notification) {
        let text = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            isSearching = false
            searchResults = []
        } else {
            isSearching = true
            searchResults = StartMenuSearchEngine.shared.search(query: text)
            selectedIndex = 0
        }
        scrollOffsetY = 0
        recomputeScrollBounds()
        needsDisplay = true
    }

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        let area = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }

    override public func scrollWheel(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        // Scroll when cursor is over the app list column (or anywhere left of tiles)
        if loc.x < bounds.width - 300 || event.window == nil {
            recomputeScrollBounds()
            scrollOffsetY = min(maxScrollY, max(0, scrollOffsetY - event.deltaY * 10))
        } else {
            tileScrollOffsetY = min(maxTileScrollY, max(0, tileScrollOffsetY - event.deltaY * 10))
        }
        needsDisplay = true
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        // 1. Check Rail
        if loc.x < 48 {
            let railIndex: Int?
            if loc.y >= bounds.height - 44 { railIndex = 0 }
            else if loc.y >= 104 && loc.y < 144 { railIndex = 1 }
            else if loc.y >= 64 && loc.y < 104 { railIndex = 2 }
            else if loc.y >= 36 && loc.y < 64 { railIndex = 3 }
            else if loc.y < 36 { railIndex = 4 }
            else { railIndex = nil }

            if hoveredSection != 0 || hoveredIndex != railIndex {
                hoveredSection = 0
                hoveredIndex = railIndex
                needsDisplay = true
            }
            return
        }

        // 2. Check App List
        let listW = max(232, bounds.width - 48 - 320)
        let listRect = NSRect(x: 52, y: 0, width: listW, height: bounds.height - 44)
        if listRect.contains(loc) {
            let itemH: CGFloat = 32
            let totalCount = isSearching ? searchResults.count : appList.count
            let clickY = listRect.maxY - loc.y + scrollOffsetY
            let idx = Int(clickY / itemH)
            let validIdx = (idx >= 0 && idx < totalCount) ? idx : nil

            if hoveredSection != 1 || hoveredIndex != validIdx {
                hoveredSection = 1
                hoveredIndex = validIdx
                needsDisplay = true
            }
            return
        }

        // 3. Check Tiles
        var foundTileIdx: Int? = nil
        for item in tileRects {
            let visibleRect = item.rect.offsetBy(dx: 0, dy: tileScrollOffsetY)
            if visibleRect.contains(loc) {
                foundTileIdx = item.index
                break
            }
        }

        if hoveredSection != 2 || hoveredIndex != foundTileIdx {
            hoveredSection = 2
            hoveredIndex = foundTileIdx
            needsDisplay = true
        }
    }

    override public func mouseExited(with event: NSEvent) {
        if hoveredSection != nil || hoveredIndex != nil {
            hoveredSection = nil
            hoveredIndex = nil
            needsDisplay = true
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Windows 10 Charcoal Acrylic Background (#121212)
        NSColor(srgbRed: 0.08, green: 0.08, blue: 0.08, alpha: 0.98).setFill()
        bounds.fill()

        // 1. Left Narrow Icon Rail (48px wide)
        let railRect = NSRect(x: 0, y: 0, width: 48, height: bounds.height)
        NSColor(srgbRed: 0.05, green: 0.05, blue: 0.05, alpha: 1.0).setFill()
        railRect.fill()

        drawRailIcon(icon: "≡", y: bounds.height - 40, isHovered: (hoveredSection == 0 && hoveredIndex == 0), isSelected: (selectedSection == 0 && selectedIndex == 0))
        drawRailIcon(icon: "👤", y: 114, isHovered: (hoveredSection == 0 && hoveredIndex == 1), isSelected: (selectedSection == 0 && selectedIndex == 1))
        drawRailIcon(icon: "📁", y: 76, isHovered: (hoveredSection == 0 && hoveredIndex == 2), isSelected: (selectedSection == 0 && selectedIndex == 2))
        drawRailIcon(icon: "⚙", y: 40, isHovered: (hoveredSection == 0 && hoveredIndex == 3), isSelected: (selectedSection == 0 && selectedIndex == 3))
        drawRailIcon(icon: "⏻", y: 6, isHovered: (hoveredSection == 0 && hoveredIndex == 4), isSelected: (selectedSection == 0 && selectedIndex == 4))

        // 2. Middle App List Column
        let listW = max(232, bounds.width - 48 - 320)
        let listRect = NSRect(x: 52, y: 0, width: listW, height: bounds.height - 44)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.clip(to: listRect)

        let itemH: CGFloat = 32
        if isSearching {
            for (index, item) in searchResults.enumerated() {
                let itemY = listRect.maxY - CGFloat(index + 1) * itemH + scrollOffsetY
                let itemRect = NSRect(x: listRect.minX + 4, y: itemY, width: listRect.width - 12, height: itemH)
                if itemRect.maxY < 0 || itemRect.minY > listRect.maxY { continue }

                let isSelected = (selectedSection == 1 && selectedIndex == index)
                let isHovered = (hoveredSection == 1 && hoveredIndex == index)
                if isSelected {
                    NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 0.9).setFill()
                    itemRect.fill()
                } else if isHovered {
                    NSColor(white: 1.0, alpha: 0.12).setFill()
                    itemRect.fill()
                }

                item.icon.draw(in: NSRect(x: itemRect.minX + 5, y: itemRect.midY - 10, width: 20, height: 20))
                let str = StartMenuText.fitted(item.title, font: NSFont.systemFont(ofSize: 11.5), color: .white, maxWidth: itemRect.maxX - (itemRect.minX + 32) - 4)
                str.draw(at: NSPoint(x: itemRect.minX + 32, y: itemRect.midY - 6))
            }
        } else {
            for (index, app) in appList.enumerated() {
                let itemY = listRect.maxY - CGFloat(index + 1) * itemH + scrollOffsetY
                let itemRect = NSRect(x: listRect.minX + 4, y: itemY, width: listRect.width - 12, height: itemH)
                if itemRect.maxY < 0 || itemRect.minY > listRect.maxY { continue }

                let isSelected = (selectedSection == 1 && selectedIndex == index)
                let isHovered = (hoveredSection == 1 && hoveredIndex == index)
                if isSelected {
                    NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 0.85).setFill()
                    itemRect.fill()
                } else if isHovered {
                    NSColor(white: 1.0, alpha: 0.10).setFill()
                    itemRect.fill()
                    NSColor(white: 1.0, alpha: 0.22).setStroke()
                    let b = NSBezierPath(rect: itemRect.insetBy(dx: 0.5, dy: 0.5))
                    b.lineWidth = 1
                    b.stroke()
                }

                app.icon.draw(in: NSRect(x: itemRect.minX + 5, y: itemRect.midY - 10, width: 20, height: 20))
                let str = StartMenuText.fitted(app.name, font: NSFont.systemFont(ofSize: 11.5), color: .white, maxWidth: itemRect.maxX - (itemRect.minX + 32) - 4)
                str.draw(at: NSPoint(x: itemRect.minX + 32, y: itemRect.midY - 6))
            }
        }

        context.restoreGState()

        // Windows 10 Thin Scrollbar on App List
        if maxScrollY > 0 {
            let scrollTrackRect = NSRect(x: listRect.maxX - 4, y: listRect.minY + 4, width: 3, height: listRect.height - 8)
            NSColor(white: 1.0, alpha: 0.12).setFill()
            scrollTrackRect.fill()

            let thumbH = max(24, (listRect.height / (listRect.height + maxScrollY)) * scrollTrackRect.height)
            let thumbY = scrollTrackRect.maxY - thumbH - (scrollOffsetY / maxScrollY) * (scrollTrackRect.height - thumbH)
            let thumbRect = NSRect(x: scrollTrackRect.minX, y: thumbY, width: 3, height: thumbH)
            NSColor(white: 1.0, alpha: 0.55).setFill()
            thumbRect.fill()
        }

        // 3. Right Pinned Live Tiles. The panel is independently clipped and
        // scrollable so a growing set of tiles never hangs below the menu.
        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor(white: 0.85, alpha: 1.0)
        ]
        let sectionStr = NSAttributedString(string: "Life at a glance", attributes: sectionTitleAttrs)
        let tilesX = bounds.width - 320
        sectionStr.draw(at: NSPoint(x: max(296, tilesX + 12), y: bounds.height - 28))

        context.saveGState()
        context.clip(to: tileViewportRect)
        for item in tileRects {
            let visibleRect = item.rect.offsetBy(dx: 0, dy: tileScrollOffsetY)
            if visibleRect.maxY < tileViewportRect.minY || visibleRect.minY > tileViewportRect.maxY { continue }

            item.tile.color.setFill()
            visibleRect.fill()

            let isHovered = (hoveredSection == 2 && hoveredIndex == item.index)
            let isSelected = (selectedSection == 2 && selectedIndex == item.index)
            let isDropTarget = (isDragging && dragCurrentTargetIndex == item.index)

            if isHovered || isSelected || isDropTarget {
                NSColor.white.withAlphaComponent(isDropTarget ? 0.35 : (isHovered ? 0.15 : 0.25)).setFill()
                visibleRect.fill()

                NSColor.white.setStroke()
                let border = NSBezierPath(rect: visibleRect.insetBy(dx: 1, dy: 1))
                border.lineWidth = (isSelected || isDropTarget) ? 2.0 : 1.0
                border.stroke()
            }

            item.tile.icon.draw(in: NSRect(x: visibleRect.minX + 7, y: visibleRect.maxY - 34, width: 26, height: 26))
            let tStr = StartMenuText.fitted(item.tile.title, font: NSFont.systemFont(ofSize: 10.5, weight: .bold), color: .white, maxWidth: visibleRect.width - 16)
            tStr.draw(at: NSPoint(x: visibleRect.minX + 8, y: visibleRect.minY + 6))
        }
        context.restoreGState()

        if maxTileScrollY > 0 {
            let trackRect = NSRect(x: bounds.width - 8, y: tileViewportRect.minY, width: 3, height: tileViewportRect.height)
            NSColor(white: 1.0, alpha: 0.12).setFill()
            trackRect.fill()
            let thumbH = max(24, trackRect.height * (tileViewportRect.height / (tileViewportRect.height + maxTileScrollY)))
            let thumbY = trackRect.maxY - thumbH - (tileScrollOffsetY / maxTileScrollY) * (trackRect.height - thumbH)
            NSColor(white: 1.0, alpha: 0.55).setFill()
            NSRect(x: trackRect.minX, y: thumbY, width: trackRect.width, height: thumbH).fill()
        }
    }

    private func drawRailIcon(icon: String, y: CGFloat, isHovered: Bool, isSelected: Bool) {
        let r = NSRect(x: 4, y: y, width: 40, height: 32)
        if isSelected {
            NSColor(white: 1.0, alpha: 0.25).setFill()
            r.fill()
        } else if isHovered {
            NSColor(white: 1.0, alpha: 0.14).setFill()
            r.fill()
            NSColor(white: 1.0, alpha: 0.22).setStroke()
            let b = NSBezierPath(rect: r.insetBy(dx: 0.5, dy: 0.5))
            b.lineWidth = 1
            b.stroke()
        }
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: NSColor.white]
        let str = NSAttributedString(string: icon, attributes: attrs)
        str.draw(at: NSPoint(x: r.midX - 8, y: r.midY - 10))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if tileViewportRect.contains(loc) {
            for item in tileRects {
                let visibleRect = item.rect.offsetBy(dx: 0, dy: tileScrollOffsetY)
                if visibleRect.contains(loc) {
                    selectedSection = 2
                    selectedIndex = item.index
                    dragStartIndex = item.index
                    dragMouseDownPoint = loc
                    isDragging = false
                    needsDisplay = true
                    return
                }
            }
        }
        super.mouseDown(with: event)
    }

    override public func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if let start = dragMouseDownPoint, hypot(loc.x - start.x, loc.y - start.y) > 4, dragStartIndex != nil {
            isDragging = true
            var foundTarget: Int? = nil
            for item in tileRects {
                let visibleRect = item.rect.offsetBy(dx: 0, dy: tileScrollOffsetY)
                if visibleRect.contains(loc) {
                    foundTarget = item.index
                    break
                }
            }
            dragCurrentTargetIndex = foundTarget
            needsDisplay = true
        }
    }

    override public func rightMouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        // Check Right Click on Tiles
        if tileViewportRect.contains(loc) {
            for item in tileRects {
                let visibleRect = item.rect.offsetBy(dx: 0, dy: tileScrollOffsetY)
                if visibleRect.contains(loc) {
                    let menu = NSMenu(title: item.tile.title)

                    let openItem = NSMenuItem(title: "Open", action: #selector(contextOpenClicked(_:)), keyEquivalent: "")
                    openItem.target = self
                    openItem.tag = item.index
                    menu.addItem(openItem)

                    menu.addItem(NSMenuItem.separator())

                    let unpinItem = NSMenuItem(title: "Unpin from Start", action: #selector(contextUnpinClicked(_:)), keyEquivalent: "")
                    unpinItem.target = self
                    unpinItem.representedObject = item.tile.id
                    menu.addItem(unpinItem)

                    if item.index > 0 {
                        let moveTopItem = NSMenuItem(title: "Move to Top", action: #selector(contextMoveTopClicked(_:)), keyEquivalent: "")
                        moveTopItem.target = self
                        moveTopItem.tag = item.index
                        menu.addItem(moveTopItem)
                    }

                    menu.addItem(NSMenuItem.separator())

                    let resetItem = NSMenuItem(title: "Reset Tiles to Default", action: #selector(contextResetClicked), keyEquivalent: "")
                    resetItem.target = self
                    menu.addItem(resetItem)

                    NSMenu.popUpContextMenu(menu, with: event, for: self)
                    return
                }
            }
        }

        // Check Right Click on App List
        let listW = max(232, bounds.width - 48 - 320)
        let listRect = NSRect(x: 52, y: 0, width: listW, height: bounds.height - 44)
        if listRect.contains(loc) && !isSearching {
            let itemH: CGFloat = 32
            let clickY = listRect.maxY - loc.y + scrollOffsetY
            let idx = Int(clickY / itemH)
            if idx >= 0 && idx < appList.count {
                let app = appList[idx]
                let menu = NSMenu(title: app.name)
                let isAlreadyPinned = PinnedProgramsManager.shared.isPinned(id: app.id, in: "org.taskintosh.era.windows10")

                if isAlreadyPinned {
                    let unpinItem = NSMenuItem(title: "Unpin from Start", action: #selector(contextUnpinAppClicked(_:)), keyEquivalent: "")
                    unpinItem.target = self
                    unpinItem.representedObject = app.id
                    menu.addItem(unpinItem)
                } else {
                    let pinItem = NSMenuItem(title: "Pin to Start", action: #selector(contextPinAppClicked(_:)), keyEquivalent: "")
                    pinItem.target = self
                    pinItem.tag = idx
                    menu.addItem(pinItem)
                }

                NSMenu.popUpContextMenu(menu, with: event, for: self)
                return
            }
        }

        super.rightMouseDown(with: event)
    }

    @objc private func contextOpenClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        if idx >= 0 && idx < pinnedTiles.count {
            onDismiss?()
            pinnedTiles[idx].action()
        }
    }

    @objc private func contextUnpinClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        PinnedProgramsManager.shared.unpin(id: id, in: "org.taskintosh.era.windows10")
        setupContent()
        needsDisplay = true
    }

    @objc private func contextMoveTopClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx > 0 else { return }
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: 0, in: "org.taskintosh.era.windows10")
        setupContent()
        needsDisplay = true
    }

    @objc private func contextResetClicked() {
        PinnedProgramsManager.shared.resetToDefaults(for: "org.taskintosh.era.windows10")
        setupContent()
        needsDisplay = true
    }

    @objc private func contextPinAppClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx >= 0 && idx < appList.count else { return }
        let app = appList[idx]
        let newItem = PinnedProgramItem(
            id: app.id,
            title: app.name,
            path: app.url.path,
            iconType: "programs",
            isWide: false,
            colorHex: "#0078D7"
        )
        PinnedProgramsManager.shared.pin(item: newItem, in: "org.taskintosh.era.windows10")
        setupContent()
        needsDisplay = true
    }

    @objc private func contextUnpinAppClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        PinnedProgramsManager.shared.unpin(id: id, in: "org.taskintosh.era.windows10")
        setupContent()
        needsDisplay = true
    }

    override public func mouseUp(with event: NSEvent) {
        if isDragging {
            if let from = dragStartIndex, let to = dragCurrentTargetIndex, from != to {
                PinnedProgramsManager.shared.reorder(fromIndex: from, toIndex: to, in: "org.taskintosh.era.windows10")
                setupContent()
            }
            dragStartIndex = nil
            dragCurrentTargetIndex = nil
            isDragging = false
            dragMouseDownPoint = nil
            needsDisplay = true
            return
        }

        dragStartIndex = nil
        dragCurrentTargetIndex = nil
        isDragging = false
        dragMouseDownPoint = nil

        let loc = convert(event.locationInWindow, from: nil)

        // Check Rail
        if loc.x < 48 {
            onDismiss?()
            if loc.y < 36 {
                // Power
                AppDelegate.shared?.openShutDownDialog()
            } else if loc.y < 70 {
                // Settings
                MacOSLocationsService.shared.openSystemSettings()
            } else if loc.y < 108 {
                // Documents
                MacOSLocationsService.shared.openURL(MacOSLocationsService.shared.documentsURL)
            } else if loc.y < 144 {
                // User
                MacOSLocationsService.shared.openURL(MacOSLocationsService.shared.homeURL)
            }
            return
        }

        // Check App List
        let listW = max(232, bounds.width - 48 - 320)
        let listRect = NSRect(x: 52, y: 0, width: listW, height: bounds.height - 44)
        if listRect.contains(loc) {
            let itemH: CGFloat = 32
            let clickY = listRect.maxY - loc.y + scrollOffsetY
            let idx = Int(clickY / itemH)

            if isSearching {
                if idx >= 0 && idx < searchResults.count {
                    onDismiss?()
                    searchResults[idx].action()
                }
            } else {
                if idx >= 0 && idx < appList.count {
                    onDismiss?()
                    AppCatalog.shared.launch(appList[idx])
                }
            }
            return
        }

        // Check Tiles
        for item in tileRects {
            let visibleRect = item.rect.offsetBy(dx: 0, dy: tileScrollOffsetY)
            if visibleRect.contains(loc) {
                onDismiss?()
                item.tile.action()
                return
            }
        }
    }

    public func handleKeyDown(event: NSEvent) -> Bool {
        if event.keyCode == 48 { // Tab
            selectedSection = (selectedSection + 1) % 3
            selectedIndex = 0
            needsDisplay = true
            return true
        } else if event.keyCode == 126 { // Up
            if selectedSection == 1 {
                let maxCount = isSearching ? searchResults.count : appList.count
                if maxCount > 0 {
                    selectedIndex = (selectedIndex - 1 + maxCount) % maxCount
                    // Auto-scroll into view
                    let itemH: CGFloat = 32
                    let itemTop = CGFloat(selectedIndex) * itemH
                    if itemTop < scrollOffsetY { scrollOffsetY = itemTop }
                }
            } else if selectedSection == 2 {
                selectedIndex = (selectedIndex - 1 + pinnedTiles.count) % pinnedTiles.count
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 125 { // Down
            if selectedSection == 1 {
                let maxCount = isSearching ? searchResults.count : appList.count
                if maxCount > 0 {
                    selectedIndex = (selectedIndex + 1) % maxCount
                    // Auto-scroll into view
                    let itemH: CGFloat = 32
                    let listH = bounds.height - 44
                    let itemBottom = CGFloat(selectedIndex + 1) * itemH
                    if itemBottom > scrollOffsetY + listH { scrollOffsetY = itemBottom - listH }
                }
            } else if selectedSection == 2 {
                selectedIndex = (selectedIndex + 1) % pinnedTiles.count
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 123 { // Left
            if selectedSection > 0 { selectedSection -= 1 }
            needsDisplay = true
            return true
        } else if event.keyCode == 124 { // Right
            if selectedSection < 2 { selectedSection += 1 }
            needsDisplay = true
            return true
        } else if event.keyCode == 36 || event.keyCode == 76 { // Return
            if selectedSection == 1 {
                if isSearching && selectedIndex < searchResults.count {
                    onDismiss?()
                    searchResults[selectedIndex].action()
                } else if !isSearching && selectedIndex < appList.count {
                    onDismiss?()
                    AppCatalog.shared.launch(appList[selectedIndex])
                }
            } else if selectedSection == 2 && selectedIndex < pinnedTiles.count {
                onDismiss?()
                pinnedTiles[selectedIndex].action()
            }
            return true
        }
        return false
    }

    private func drawSearchFieldVisual() {
        let fieldRect = searchField.frame
        NSColor(white: 0.15, alpha: 0.9).setFill()
        let path = NSBezierPath(rect: fieldRect)
        path.fill()
        NSColor(white: 1.0, alpha: 0.3).setStroke()
        path.lineWidth = 1.0
        path.stroke()

        if searchField.stringValue.isEmpty {
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor(white: 0.6, alpha: 1.0)
            ]
            let str = NSAttributedString(string: "Type here to search", attributes: placeholderAttrs)
            str.draw(at: NSPoint(x: fieldRect.minX + 8, y: fieldRect.midY - 7))
        }

        // Search icon on right
        let iconRect = NSRect(x: fieldRect.maxX - 20, y: fieldRect.midY - 8, width: 16, height: 16)
        ProceduralIcons.shared.icon(for: .search, eraType: .hybridMenu, size: 16).draw(in: iconRect)
    }

}
