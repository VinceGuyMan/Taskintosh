import AppKit
import TaskintoshKit

public final class Windows8MenuView: NSView, NSTextFieldDelegate {
    public var onDismiss: (() -> Void)?

    private let searchField = NSTextField()
    private var isSearching = false
    private var searchResults: [StartMenuSearchResult] = []
    private var selectedIndex: Int = 0
    private var hoveredTileIndex: Int? = nil
    private var trackingArea: NSTrackingArea?

    public var isWindows81Override: Bool? = nil {
        didSet {
            setupGroups()
            needsDisplay = true
        }
    }

    private var isWindows81: Bool {
        isWindows81Override ?? (EraManager.shared.activeEra.manifest.name == "Windows 8.1")
    }

    private var menuEraType: StartMenuType {
        isWindows81 ? .modernTiles : .tileLauncher
    }

    public var scrollX: CGFloat = 0
    public private(set) var maxScrollX: CGFloat = 0

    // Drag-and-drop state for tiles
    private var dragStartIndex: Int? = nil
    private var dragCurrentTargetIndex: Int? = nil
    private var isDragging: Bool = false
    private var dragMouseDownPoint: NSPoint? = nil

    public struct Win8Tile {
        public let id: String
        public let title: String
        public let subtitle: String?
        public let icon: NSImage
        public let color: NSColor
        public let isWide: Bool
        public let action: () -> Void

        public init(
            id: String = UUID().uuidString,
            title: String,
            subtitle: String? = nil,
            icon: NSImage,
            color: NSColor,
            isWide: Bool = false,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.color = color
            self.isWide = isWide
            self.action = action
        }
    }

    public struct TileGroup {
        public let title: String
        public let tiles: [Win8Tile]
    }

    public private(set) var groups: [TileGroup] = []
    private var allTiles: [Win8Tile] = []
    private var tileLayouts: [(tile: Win8Tile, rect: NSRect, index: Int)] = []

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 700, height: 470))
        setupComponents()
        setupGroups()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupComponents() {
        searchField.frame = NSRect(x: bounds.width - 230, y: bounds.height - 44, width: 200, height: 26)
        searchField.placeholderString = "Search apps & files..."
        searchField.font = NSFont.systemFont(ofSize: 12)
        searchField.delegate = self
        searchField.focusRingType = .none
        addSubview(searchField)
    }

    public func setupGroups() {
        let locations = MacOSLocationsService.shared
        let icons = ProceduralIcons.shared
        let eraType = menuEraType
        let eraID = isWindows81 ? "org.taskintosh.era.windows81" : "org.taskintosh.era.windows8"

        let pinned = PinnedProgramsManager.shared.pinnedPrograms(for: eraID)

        // Group the pinned items preserving their groupName and order
        var groupOrder: [String] = []
        var groupedItems: [String: [PinnedProgramItem]] = [:]

        for p in pinned {
            let gName = p.groupName ?? (isWindows81 ? "Apps" : "Start")
            if groupedItems[gName] == nil {
                groupOrder.append(gName)
                groupedItems[gName] = []
            }
            groupedItems[gName]?.append(p)
        }

        var loadedGroups: [TileGroup] = []
        for gName in groupOrder {
            let items = groupedItems[gName] ?? []
            var tiles: [Win8Tile] = []

            for p in items {
                let sz: CGFloat = p.isWide ? 32 : 28
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
                case "folder": icon = icons.icon(for: .folder, eraType: eraType, size: sz)
                case "accessibility": icon = icons.icon(for: .accessibility, eraType: eraType, size: sz)
                case "forceQuit": icon = icons.icon(for: .forceQuit, eraType: eraType, size: sz)
                case "eraManager": icon = icons.icon(for: .eraManager, eraType: eraType, size: sz)
                case "goToPath": icon = icons.icon(for: .goToPath, eraType: eraType, size: sz)
                case "run": icon = icons.icon(for: .run, eraType: eraType, size: sz)
                case "lock": icon = icons.icon(for: .lock, eraType: eraType, size: sz)
                case "restart": icon = icons.icon(for: .restart, eraType: eraType, size: sz)
                case "shutDown": icon = icons.icon(for: .shutDown, eraType: eraType, size: sz)
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
                    color = NSColor(srgbRed: 0.12, green: 0.58, blue: 0.95, alpha: 1.0)
                }

                let action: () -> Void = {
                    switch p.id {
                    case "w8.desktop": locations.openURL(locations.desktopURL)
                    case "w8.internet": NSWorkspace.shared.open(URL(string: "https://www.google.com")!)
                    case "w8.terminal": locations.openTerminal()
                    case "w8.calc": NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calculator.app"))
                    case "w8.settings": locations.openSystemSettings()
                    case "w8.docs": locations.openURL(locations.documentsURL)
                    case "w8.downloads": locations.openURL(locations.downloadsURL)
                    case "w8.pictures": locations.openURL(locations.picturesURL)
                    case "w8.computer": locations.openURL(URL(fileURLWithPath: "/Volumes"))
                    case "w8.userlib": locations.openURL(locations.userLibraryURL)
                    case "w8.syslib": locations.openURL(locations.systemLibraryURL)
                    case "w8.actmon": locations.openActivityMonitor()
                    case "w8.access": locations.openAccessibilitySettings()
                    case "w8.forcequit": locations.confirmAndForceQuit()
                    case "w8.era": AppDelegate.shared?.openEraManager()
                    case "w8.update": AppDelegate.shared?.openWindowsUpdate()
                    case "w8.path": AppDelegate.shared?.openGoToPathDialog()
                    case "w8.run": AppDelegate.shared?.openRunDialog()
                    case "w8.sleep": locations.confirmAndSleep()
                    case "w8.restart": locations.confirmAndRestart()
                    case "w8.shutdown": locations.confirmAndShutDown()
                    default:
                        if let path = p.path {
                            NSWorkspace.shared.open(URL(fileURLWithPath: path))
                        }
                    }
                }

                tiles.append(Win8Tile(id: p.id, title: p.title, subtitle: p.subtitle, icon: icon, color: color, isWide: p.isWide, action: action))
            }

            loadedGroups.append(TileGroup(title: gName, tiles: tiles))
        }

        groups = loadedGroups
        allTiles = groups.flatMap { $0.tiles }
        rebuildLayouts()
    }

    private func rebuildLayouts() {
        tileLayouts.removeAll()
        var globalIndex = 0

        let tileH: CGFloat = 82
        let standardW: CGFloat = 90
        let spacing: CGFloat = 8
        let groupSpacing: CGFloat = 36

        var curGroupX: CGFloat = 28
        let startY = bounds.height - 96 - tileH

        for group in groups {
            var occupied = Array(repeating: Array(repeating: false, count: 3), count: 20)
            var maxGroupCol = 0

            for tile in group.tiles {
                let isWide = tile.isWide
                var placed = false

                for c in 0..<18 {
                    if placed { break }
                    for r in 0..<3 {
                        if !occupied[c][r] {
                            if isWide {
                                if !occupied[c + 1][r] {
                                    occupied[c][r] = true
                                    occupied[c + 1][r] = true
                                    maxGroupCol = max(maxGroupCol, c + 1)
                                    let x = curGroupX + CGFloat(c) * (standardW + spacing)
                                    let y = startY - CGFloat(r) * (tileH + spacing)
                                    let w = 2 * standardW + spacing
                                    let rect = NSRect(x: x, y: y, width: w, height: tileH)
                                    tileLayouts.append((tile: tile, rect: rect, index: globalIndex))
                                    globalIndex += 1
                                    placed = true
                                    break
                                }
                            } else {
                                occupied[c][r] = true
                                maxGroupCol = max(maxGroupCol, c)
                                let x = curGroupX + CGFloat(c) * (standardW + spacing)
                                let y = startY - CGFloat(r) * (tileH + spacing)
                                let rect = NSRect(x: x, y: y, width: standardW, height: tileH)
                                tileLayouts.append((tile: tile, rect: rect, index: globalIndex))
                                globalIndex += 1
                                placed = true
                                break
                            }
                        }
                    }
                }
            }

            let groupWidth = CGFloat(maxGroupCol + 1) * (standardW + spacing)
            curGroupX += groupWidth + groupSpacing
        }

        let totalW = curGroupX + 60
        maxScrollX = max(0, totalW - bounds.width)
        scrollX = min(scrollX, maxScrollX)
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        searchField.frame = NSRect(x: newSize.width - 230, y: newSize.height - 44, width: 200, height: 26)
        rebuildLayouts()
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
        if isSearching { return }
        // On macOS, trackpad swipes produce deltaX, while traditional mouse wheels produce deltaY.
        // In authentic Windows 8.1, both scroll the Start screen horizontally!
        let delta = abs(event.deltaX) > abs(event.deltaY) ? event.deltaX : event.deltaY
        scrollX = min(maxScrollX, max(0, scrollX - delta * 12))
        needsDisplay = true
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if isSearching { return }

        var foundIndex: Int? = nil
        for item in tileLayouts {
            let visibleRect = NSRect(
                x: item.rect.minX - scrollX,
                y: item.rect.minY,
                width: item.rect.width,
                height: item.rect.height
            )
            if visibleRect.contains(loc) {
                foundIndex = item.index
                break
            }
        }

        if hoveredTileIndex != foundIndex {
            hoveredTileIndex = foundIndex
            needsDisplay = true
        }
    }

    override public func mouseExited(with event: NSEvent) {
        if hoveredTileIndex != nil {
            hoveredTileIndex = nil
            needsDisplay = true
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Windows 8 uses a brighter flat-blue Start screen. Windows 8.1
        // shifts to a deeper personalized slate/violet field with softer
        // structure behind the tiles.
        let bgGradient = isWindows81
            ? NSGradient(colors: [
                NSColor(srgbRed: 0.08, green: 0.22, blue: 0.38, alpha: 0.99),
                NSColor(srgbRed: 0.16, green: 0.08, blue: 0.30, alpha: 0.99)
            ])
            : NSGradient(colors: [
                NSColor(srgbRed: 0.05, green: 0.32, blue: 0.46, alpha: 0.99),
                NSColor(srgbRed: 0.02, green: 0.18, blue: 0.28, alpha: 0.99)
            ])
        bgGradient?.draw(in: bounds, angle: -45)

        // Subtle geometric background layer lines, with a diagonal 8.1
        // personalization motif instead of the flatter Windows 8 grid.
        NSColor.white.withAlphaComponent(isWindows81 ? 0.035 : 0.03).setStroke()
        let gridPath = NSBezierPath()
        if isWindows81 {
            for x in stride(from: -bounds.height, to: bounds.width, by: 72) {
                gridPath.move(to: NSPoint(x: x, y: 0))
                gridPath.line(to: NSPoint(x: x + bounds.height, y: bounds.height))
            }
        } else {
            for x in stride(from: 0, to: bounds.width, by: 48) {
                gridPath.move(to: NSPoint(x: x, y: 0))
                gridPath.line(to: NSPoint(x: x, y: bounds.height))
            }
        }
        gridPath.stroke()

        // 2. Header Title "Start"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .light),
            .foregroundColor: NSColor.white
        ]
        let titleStr = NSAttributedString(string: "Start", attributes: titleAttrs)
        titleStr.draw(at: NSPoint(x: 28, y: bounds.height - 48))

        // User name and avatar badge
        let userStr = NSFullUserName().isEmpty ? NSUserName() : NSFullUserName()
        let userAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor(white: 0.90, alpha: 1.0)
        ]
        let userAttrStr = NSAttributedString(string: userStr, attributes: userAttrs)
        userAttrStr.draw(at: NSPoint(x: 104, y: bounds.height - 38))

        if isSearching {
            drawSearchResults()
            return
        }

        // 3. Draw Tile Groups & Tiles clipped to the main canvas
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()

        let contentRect = NSRect(x: 0, y: 16, width: bounds.width, height: bounds.height - 64)
        context.clip(to: contentRect)

        // Draw Group Headers
        var curX: CGFloat = 28
        let standardW: CGFloat = 90
        let wideW: CGFloat = 188
        let spacing: CGFloat = 8
        let groupSpacing: CGFloat = 36

        for group in groups {
            let headerX = curX - scrollX
            if headerX > -200 && headerX < bounds.width + 100 {
                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: NSColor(white: 0.92, alpha: 1.0)
                ]
                let hStr = NSAttributedString(string: group.title, attributes: headerAttrs)
                hStr.draw(at: NSPoint(x: headerX, y: bounds.height - 86))
            }

            // Advance by width of group
            var colCount: CGFloat = 1
            var colItems = 0
            for tile in group.tiles {
                if tile.isWide { colCount += 1 }
                colItems += 1
                if colItems >= 3 {
                    colCount += 1
                    colItems = 0
                }
            }
            let groupW = max(wideW, colCount * (standardW + spacing))
            curX += groupW + groupSpacing
        }

        // Draw Tiles
        for item in tileLayouts {
            let tileRect = NSRect(
                x: item.rect.minX - scrollX,
                y: item.rect.minY,
                width: item.rect.width,
                height: item.rect.height
            )

            // Skip off-screen tiles
            if tileRect.maxX < -20 || tileRect.minX > bounds.width + 20 { continue }

            // Tile Background Fill
            item.tile.color.setFill()
            tileRect.fill()

            let isHovered = (hoveredTileIndex == item.index)
            let isSelected = (selectedIndex == item.index)
            let isDropTarget = (isDragging && dragCurrentTargetIndex == item.index)

            // Hover / Selection / Drop Target Highlight (Authentic Windows 8 tile lift / outline)
            if isHovered || isSelected || isDropTarget {
                NSColor.white.withAlphaComponent(isDropTarget ? 0.35 : (isHovered ? 0.16 : 0.24)).setFill()
                tileRect.fill()

                NSColor.white.setStroke()
                let border = NSBezierPath(rect: tileRect.insetBy(dx: 1, dy: 1))
                border.lineWidth = (isSelected || isDropTarget) ? 2.5 : 1.5
                border.stroke()
            }

            // Icon
            item.tile.icon.draw(in: NSRect(x: tileRect.minX + 8, y: tileRect.maxY - 38, width: 30, height: 30))

            // Title
            let tStr = StartMenuText.fitted(item.tile.title, font: NSFont.systemFont(ofSize: 11.5, weight: .bold), color: .white, maxWidth: tileRect.width - 16)
            tStr.draw(at: NSPoint(x: tileRect.minX + 8, y: tileRect.minY + 20))

            // Subtitle
            if let sub = item.tile.subtitle {
                let sStr = StartMenuText.fitted(sub, font: NSFont.systemFont(ofSize: 9.5), color: NSColor(white: 0.90, alpha: 1.0), maxWidth: tileRect.width - 16)
                sStr.draw(at: NSPoint(x: tileRect.minX + 8, y: tileRect.minY + 6))
            }
        }

        context.restoreGState()

        // 4. Horizontal Scroll Indicator Track at Bottom
        if maxScrollX > 0 {
            let trackW: CGFloat = min(240, bounds.width - 80)
            let trackRect = NSRect(x: (bounds.width - trackW) / 2.0, y: 6, width: trackW, height: 4)
            NSColor.white.withAlphaComponent(0.15).setFill()
            NSBezierPath(roundedRect: trackRect, xRadius: 2, yRadius: 2).fill()

            let thumbW: CGFloat = max(36, trackW * (bounds.width / (bounds.width + maxScrollX)))
            let thumbX = trackRect.minX + (trackW - thumbW) * (scrollX / maxScrollX)
            let thumbRect = NSRect(x: thumbX, y: 6, width: thumbW, height: 4)
            NSColor.white.withAlphaComponent(0.55).setFill()
            NSBezierPath(roundedRect: thumbRect, xRadius: 2, yRadius: 2).fill()
        }
    }

    private func drawSearchResults() {
        let resultsRect = NSRect(x: 28, y: 24, width: bounds.width - 56, height: bounds.height - 84)
        let itemH: CGFloat = 36

        for (index, item) in searchResults.prefix(10).enumerated() {
            let itemRect = NSRect(x: resultsRect.minX, y: resultsRect.maxY - CGFloat(index + 1) * itemH, width: resultsRect.width, height: itemH)
            let isSelected = (selectedIndex == index)
            if isSelected {
                NSColor(srgbRed: 0.12, green: 0.58, blue: 0.95, alpha: 0.9).setFill()
                itemRect.fill()
            } else {
                NSColor(white: 0.0, alpha: 0.25).setFill()
                itemRect.fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 8, y: itemRect.midY - 11, width: 22, height: 22))
            let str = StartMenuText.fitted(item.title, font: NSFont.boldSystemFont(ofSize: 12), color: .white, maxWidth: itemRect.maxX - (itemRect.minX + 38) - 208)
            str.draw(at: NSPoint(x: itemRect.minX + 38, y: itemRect.midY - 7))

            if !item.subtitle.isEmpty {
                let sStr = StartMenuText.fitted(item.subtitle, font: NSFont.systemFont(ofSize: 10), color: NSColor(white: 0.85, alpha: 1.0), maxWidth: 192)
                sStr.draw(at: NSPoint(x: itemRect.maxX - 200, y: itemRect.midY - 6))
            }
        }
    }

    override public func mouseDown(with event: NSEvent) {
        if isSearching {
            super.mouseDown(with: event)
            return
        }
        let loc = convert(event.locationInWindow, from: nil)
        for item in tileLayouts {
            let visibleRect = NSRect(
                x: item.rect.minX - scrollX,
                y: item.rect.minY,
                width: item.rect.width,
                height: item.rect.height
            )
            if visibleRect.contains(loc) {
                selectedIndex = item.index
                dragStartIndex = item.index
                dragMouseDownPoint = loc
                isDragging = false
                needsDisplay = true
                return
            }
        }
        super.mouseDown(with: event)
    }

    override public func mouseDragged(with event: NSEvent) {
        if isSearching { return }
        let loc = convert(event.locationInWindow, from: nil)
        if let start = dragMouseDownPoint, hypot(loc.x - start.x, loc.y - start.y) > 4, dragStartIndex != nil {
            isDragging = true
            var foundTarget: Int? = nil
            for item in tileLayouts {
                let visibleRect = NSRect(
                    x: item.rect.minX - scrollX,
                    y: item.rect.minY,
                    width: item.rect.width,
                    height: item.rect.height
                )
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
        if isSearching {
            super.rightMouseDown(with: event)
            return
        }
        let loc = convert(event.locationInWindow, from: nil)
        for item in tileLayouts {
            let visibleRect = NSRect(
                x: item.rect.minX - scrollX,
                y: item.rect.minY,
                width: item.rect.width,
                height: item.rect.height
            )
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
                    let moveStartItem = NSMenuItem(title: "Move to Beginning", action: #selector(contextMoveStartClicked(_:)), keyEquivalent: "")
                    moveStartItem.target = self
                    moveStartItem.tag = item.index
                    menu.addItem(moveStartItem)
                }

                menu.addItem(NSMenuItem.separator())

                let resetItem = NSMenuItem(title: "Reset Tiles to Default", action: #selector(contextResetClicked), keyEquivalent: "")
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
        if idx >= 0 && idx < allTiles.count {
            onDismiss?()
            allTiles[idx].action()
        }
    }

    @objc private func contextUnpinClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let eraID = isWindows81 ? "org.taskintosh.era.windows81" : "org.taskintosh.era.windows8"
        PinnedProgramsManager.shared.unpin(id: id, in: eraID)
        setupGroups()
        needsDisplay = true
    }

    @objc private func contextMoveStartClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx > 0 else { return }
        let eraID = isWindows81 ? "org.taskintosh.era.windows81" : "org.taskintosh.era.windows8"
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: 0, in: eraID)
        setupGroups()
        needsDisplay = true
    }

    @objc private func contextResetClicked() {
        let eraID = isWindows81 ? "org.taskintosh.era.windows81" : "org.taskintosh.era.windows8"
        PinnedProgramsManager.shared.resetToDefaults(for: eraID)
        setupGroups()
        needsDisplay = true
    }

    override public func mouseUp(with event: NSEvent) {
        if isDragging {
            let eraID = isWindows81 ? "org.taskintosh.era.windows81" : "org.taskintosh.era.windows8"
            if let from = dragStartIndex, let to = dragCurrentTargetIndex, from != to {
                PinnedProgramsManager.shared.reorder(fromIndex: from, toIndex: to, in: eraID)
                setupGroups()
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
        if isSearching {
            let resultsRect = NSRect(x: 28, y: 24, width: bounds.width - 56, height: bounds.height - 84)
            let itemH: CGFloat = 36
            let idx = Int((resultsRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < min(10, searchResults.count) {
                onDismiss?()
                searchResults[idx].action()
            }
            return
        }

        for item in tileLayouts {
            let visibleRect = NSRect(
                x: item.rect.minX - scrollX,
                y: item.rect.minY,
                width: item.rect.width,
                height: item.rect.height
            )
            if visibleRect.contains(loc) {
                onDismiss?()
                item.tile.action()
                return
            }
        }
    }

    public func handleKeyDown(event: NSEvent) -> Bool {
        if isSearching {
            if event.keyCode == 126 { // Up
                if searchResults.count > 0 { selectedIndex = (selectedIndex - 1 + searchResults.count) % searchResults.count }
                needsDisplay = true
                return true
            } else if event.keyCode == 125 { // Down
                if searchResults.count > 0 { selectedIndex = (selectedIndex + 1) % searchResults.count }
                needsDisplay = true
                return true
            } else if event.keyCode == 36 || event.keyCode == 76 { // Return
                if selectedIndex < searchResults.count {
                    onDismiss?()
                    searchResults[selectedIndex].action()
                    return true
                }
            }
            return false
        }

        if event.keyCode == 126 { // Up
            selectedIndex = (selectedIndex - 1 + allTiles.count) % allTiles.count
            needsDisplay = true
            return true
        } else if event.keyCode == 125 { // Down
            selectedIndex = (selectedIndex + 1) % allTiles.count
            needsDisplay = true
            return true
        } else if event.keyCode == 123 { // Left
            selectedIndex = max(0, selectedIndex - 3)
            scrollX = max(0, scrollX - 100)
            needsDisplay = true
            return true
        } else if event.keyCode == 124 { // Right
            selectedIndex = min(allTiles.count - 1, selectedIndex + 3)
            scrollX = min(maxScrollX, scrollX + 100)
            needsDisplay = true
            return true
        } else if event.keyCode == 36 || event.keyCode == 76 { // Return
            if selectedIndex < allTiles.count {
                onDismiss?()
                allTiles[selectedIndex].action()
                return true
            }
        }
        return false
    }

    private func drawSearchFieldVisual() {
        let fieldRect = searchField.frame
        NSColor(white: 0.1, alpha: 0.6).setFill()
        let path = NSBezierPath(rect: fieldRect)
        path.fill()
        NSColor(white: 1.0, alpha: 0.4).setStroke()
        path.lineWidth = 1.0
        path.stroke()

        if searchField.stringValue.isEmpty {
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor(white: 0.7, alpha: 1.0)
            ]
            let str = NSAttributedString(string: "Search", attributes: placeholderAttrs)
            str.draw(at: NSPoint(x: fieldRect.minX + 8, y: fieldRect.midY - 7))
        }

        // Search icon on right
        let iconRect = NSRect(x: fieldRect.maxX - 20, y: fieldRect.midY - 8, width: 16, height: 16)
        ProceduralIcons.shared.icon(for: .search, eraType: menuEraType, size: 16).draw(in: iconRect)
    }

}
