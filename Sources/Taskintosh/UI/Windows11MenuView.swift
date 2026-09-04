import AppKit
import TaskintoshKit

public final class Windows11MenuView: NSView, NSTextFieldDelegate {
    public var onDismiss: (() -> Void)?

    private let searchField = NSTextField()
    private var isSearching = false
    private var searchResults: [StartMenuSearchResult] = []
    private var selectedSection: Int = 1 // 0: Search, 1: Pinned, 2: Recommended, 3: Power
    private var selectedIndex: Int = 0
    private var hoveredSection: Int? = nil
    private var hoveredIndex: Int? = nil
    private var trackingArea: NSTrackingArea?

    // Drag-and-drop state for pinned apps
    private var dragStartIndex: Int? = nil
    private var dragCurrentTargetIndex: Int? = nil
    private var isDragging: Bool = false
    private var dragMouseDownPoint: NSPoint? = nil

    public struct Win11PinnedApp {
        public let id: String
        public let title: String
        public let icon: NSImage
        public let action: () -> Void

        public init(
            id: String = UUID().uuidString,
            title: String,
            icon: NSImage,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.icon = icon
            self.action = action
        }
    }

    public struct Win11RecItem {
        public let title: String
        public let subtitle: String
        public let icon: NSImage
        public let action: () -> Void
    }

    public private(set) var pinnedApps: [Win11PinnedApp] = []
    public private(set) var recommendedItems: [Win11RecItem] = []

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 560, height: 600))
        setupComponents()
        setupContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateSearchFieldFrame()
        updateTrackingAreas()
        needsDisplay = true
    }

    private func updateSearchFieldFrame() {
        let searchBarRect = NSRect(x: 32, y: bounds.height - 52, width: bounds.width - 64, height: 36)
        // Position actual NSTextField inside the drawn search pill, leaving space for the magnifying glass
        searchField.frame = NSRect(x: searchBarRect.minX + 34, y: searchBarRect.minY + 3, width: searchBarRect.width - 46, height: 30)
    }

    private func setupComponents() {
        searchField.placeholderString = "Type here to search apps, settings, and files..."
        searchField.font = NSFont.systemFont(ofSize: 12)
        searchField.delegate = self
        searchField.focusRingType = .none
        searchField.isBordered = false
        searchField.drawsBackground = false
        searchField.textColor = .white
        addSubview(searchField)
        updateSearchFieldFrame()
    }

    public func setupContent() {
        let locations = MacOSLocationsService.shared
        let icons = ProceduralIcons.shared
        let eraType = StartMenuType.centeredFlyout

        let pinned = PinnedProgramsManager.shared.pinnedPrograms(for: "org.taskintosh.era.windows11")
        var apps: [Win11PinnedApp] = []

        for p in pinned {
            let sz: CGFloat = 32
            let icon: NSImage
            switch p.iconType {
            case "internet": icon = icons.icon(for: .internet, eraType: eraType, size: sz)
            case "email": icon = icons.icon(for: .email, eraType: eraType, size: sz)
            case "settings": icon = icons.icon(for: .settings, eraType: eraType, size: sz)
            case "terminal": icon = icons.icon(for: .terminal, eraType: eraType, size: sz)
            case "programs": icon = icons.icon(for: .programs, eraType: eraType, size: sz)
            case "documents": icon = icons.icon(for: .documents, eraType: eraType, size: sz)
            case "accessibility": icon = icons.icon(for: .accessibility, eraType: eraType, size: sz)
            case "eraManager": icon = icons.icon(for: .eraManager, eraType: eraType, size: sz)
            case "goToPath": icon = icons.icon(for: .goToPath, eraType: eraType, size: sz)
            default:
                if let path = p.path {
                    icon = NSWorkspace.shared.icon(forFile: path)
                } else {
                    icon = icons.icon(for: .programs, eraType: eraType, size: sz)
                }
            }

            let action: () -> Void = {
                switch p.id {
                case "w11.safari": NSWorkspace.shared.open(URL(string: "https://www.google.com")!)
                case "w11.mail": if let url = URL(string: "mailto:") { NSWorkspace.shared.open(url) }
                case "w11.terminal": locations.openTerminal()
                case "w11.vscode": NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Visual Studio Code.app"))
                case "w11.settings": locations.openSystemSettings()
                case "w11.actmon": locations.openActivityMonitor()
                case "w11.calc": NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calculator.app"))
                case "w11.textedit": NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/TextEdit.app"))
                case "w11.files": locations.openURL(locations.homeURL)
                case "w11.access": locations.openAccessibilitySettings()
                case "w11.era": AppDelegate.shared?.openEraManager()
                case "w11.path": AppDelegate.shared?.openGoToPathDialog()
                default:
                    if let path = p.path {
                        NSWorkspace.shared.open(URL(fileURLWithPath: path))
                    }
                }
            }

            apps.append(Win11PinnedApp(id: p.id, title: p.title, icon: icon, action: action))
        }
        pinnedApps = apps

        // Recommended / Quick access items (2 columns x 3 rows = 6 items)
        recommendedItems = [
            Win11RecItem(title: "Documents", subtitle: "~/Documents", icon: icons.icon(for: .documents, eraType: eraType, size: 24)) {
                locations.openURL(locations.documentsURL)
            },
            Win11RecItem(title: "Downloads", subtitle: "~/Downloads", icon: icons.icon(for: .documents, eraType: eraType, size: 24)) {
                locations.openURL(locations.downloadsURL)
            },
            Win11RecItem(title: "Pictures", subtitle: "Photos & Screenshots", icon: icons.icon(for: .pictures, eraType: eraType, size: 24)) {
                locations.openURL(locations.picturesURL)
            },
            Win11RecItem(title: "Computer", subtitle: "Mounted Volumes", icon: icons.icon(for: .myComputer, eraType: eraType, size: 24)) {
                locations.openURL(URL(fileURLWithPath: "/Volumes"))
            },
            Win11RecItem(title: "User Library", subtitle: "~/Library", icon: icons.icon(for: .documents, eraType: eraType, size: 24)) {
                locations.openURL(locations.userLibraryURL)
            },
            Win11RecItem(title: "System Library", subtitle: "/Library", icon: icons.icon(for: .documents, eraType: eraType, size: 24)) {
                locations.openURL(locations.systemLibraryURL)
            },
            Win11RecItem(title: "Windows Update", subtitle: "System Updates", icon: icons.icon(for: .settings, eraType: eraType, size: 24)) {
                AppDelegate.shared?.openWindowsUpdate()
            }
        ]
        self.needsDisplay = true
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

    // MARK: - Geometry Calculation
    private var searchBarRect: NSRect {
        return NSRect(x: 32, y: bounds.height - 52, width: bounds.width - 64, height: 36)
    }

    private var pinnedHeaderY: CGFloat {
        return searchBarRect.minY - 26
    }

    private var pinnedGridStartY: CGFloat {
        return pinnedHeaderY - 14 - 72
    }

    private var pinnedGridBottomY: CGFloat {
        return pinnedGridStartY - 72
    }

    private var recHeaderY: CGFloat {
        return pinnedGridBottomY - 26
    }

    private var recGridStartY: CGFloat {
        return recHeaderY - 12 - 42
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        // 1. Power button in footer
        let powerRect = NSRect(x: bounds.width - 68, y: 12, width: 32, height: 32)
        if powerRect.contains(loc) {
            if hoveredSection != 3 {
                hoveredSection = 3
                hoveredIndex = nil
                needsDisplay = true
            }
            return
        }

        // 2. Search results when searching
        if isSearching {
            let listRect = NSRect(x: 32, y: 32, width: bounds.width - 64, height: bounds.height - 100)
            let itemH: CGFloat = 36
            let idx = Int((listRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < min(12, searchResults.count) {
                if hoveredSection != 0 || hoveredIndex != idx {
                    hoveredSection = 0
                    hoveredIndex = idx
                    needsDisplay = true
                }
                return
            }
        }

        // 3. Pinned Apps (6 columns x 2 rows)
        let startX: CGFloat = 36
        let gridW: CGFloat = bounds.width - 72
        let colW: CGFloat = gridW / 6.0
        let rowH: CGFloat = 72

        for (index, _) in pinnedApps.enumerated() {
            let row = index / 6
            let col = index % 6
            let itemX = startX + CGFloat(col) * colW
            let itemY = pinnedGridStartY - CGFloat(row) * rowH
            let itemRect = NSRect(x: itemX + 3, y: itemY + 3, width: colW - 6, height: rowH - 6)
            if itemRect.contains(loc) {
                if hoveredSection != 1 || hoveredIndex != index {
                    hoveredSection = 1
                    hoveredIndex = index
                    needsDisplay = true
                }
                return
            }
        }

        // 4. Recommended Items (2 columns x 3 rows)
        let recColW: CGFloat = (bounds.width - 72 - 16) / 2.0
        let recItemH: CGFloat = 42

        for (index, _) in recommendedItems.enumerated() {
            let col = index % 2
            let row = index / 2
            let itemX = startX + CGFloat(col) * (recColW + 16)
            let itemY = recGridStartY - CGFloat(row) * (recItemH + 4)
            let itemRect = NSRect(x: itemX, y: itemY, width: recColW, height: recItemH)
            if itemRect.contains(loc) {
                if hoveredSection != 2 || hoveredIndex != index {
                    hoveredSection = 2
                    hoveredIndex = index
                    needsDisplay = true
                }
                return
            }
        }

        if hoveredSection != nil || hoveredIndex != nil {
            hoveredSection = nil
            hoveredIndex = nil
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

    // MARK: - Drawing
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Frosted Mica Background with 14px rounded corners
        let path = NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14)
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.14, alpha: 0.96).setFill()
        path.fill()

        // Subtle specular border
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        path.lineWidth = 1
        path.stroke()

        // 1. Draw Top Search Bar Pill
        drawSearchBarVisual()

        if isSearching {
            drawSearchResults()
            return
        }

        // 2. Section: "Pinned" Header
        let pinnedHeaderAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12.5, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let pinnedHeaderStr = NSAttributedString(string: "Pinned", attributes: pinnedHeaderAttrs)
        pinnedHeaderStr.draw(at: NSPoint(x: 36, y: pinnedHeaderY))

        let allAppsAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(white: 0.7, alpha: 1.0)
        ]
        let allAppsStr = NSAttributedString(string: "All apps  >", attributes: allAppsAttrs)
        allAppsStr.draw(at: NSPoint(x: bounds.width - 100, y: pinnedHeaderY + 1))

        // Pinned 6x2 grid
        let startX: CGFloat = 36
        let gridW: CGFloat = bounds.width - 72
        let colW: CGFloat = gridW / 6.0
        let rowH: CGFloat = 72

        for (index, app) in pinnedApps.enumerated() {
            let row = index / 6
            let col = index % 6
            let itemX = startX + CGFloat(col) * colW
            let itemY = pinnedGridStartY - CGFloat(row) * rowH
            let itemRect = NSRect(x: itemX + 3, y: itemY + 3, width: colW - 6, height: rowH - 6)

            let isSelected = (selectedSection == 1 && selectedIndex == index)
            let isHovered = (hoveredSection == 1 && hoveredIndex == index)
            let isDropTarget = (isDragging && dragCurrentTargetIndex == index)
            if isSelected || isHovered || isDropTarget {
                NSColor(white: 1.0, alpha: isDropTarget ? 0.22 : (isSelected ? 0.16 : 0.08)).setFill()
                let pill = NSBezierPath(roundedRect: itemRect, xRadius: 8, yRadius: 8)
                pill.fill()
                if isHovered || isDropTarget {
                    NSColor(white: 1.0, alpha: isDropTarget ? 0.35 : 0.10).setStroke()
                    let b = NSBezierPath(roundedRect: itemRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
                    b.lineWidth = isDropTarget ? 1.5 : 1
                    b.stroke()
                }
            }

            // Draw Icon
            app.icon.draw(in: NSRect(x: itemRect.midX - 16, y: itemRect.maxY - 36, width: 32, height: 32))

            // Draw Title
            let titleStr = StartMenuText.fitted(app.title, font: NSFont.systemFont(ofSize: 10.5), color: .white, maxWidth: itemRect.width - 8)
            let titleSize = titleStr.size()
            titleStr.draw(at: NSPoint(x: itemRect.midX - titleSize.width / 2.0, y: itemRect.minY + 6))
        }

        // 3. Section: "Recommended" Header
        let recHeaderAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12.5, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let recHeaderStr = NSAttributedString(string: "Recommended", attributes: recHeaderAttrs)
        recHeaderStr.draw(at: NSPoint(x: 36, y: recHeaderY))

        let moreAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(white: 0.7, alpha: 1.0)
        ]
        let moreStr = NSAttributedString(string: "More  >", attributes: moreAttrs)
        moreStr.draw(at: NSPoint(x: bounds.width - 86, y: recHeaderY + 1))

        // Recommended 2-column x 3-row grid
        let recColW: CGFloat = (bounds.width - 72 - 16) / 2.0
        let recItemH: CGFloat = 42

        for (index, item) in recommendedItems.enumerated() {
            let col = index % 2
            let row = index / 2
            let itemX = startX + CGFloat(col) * (recColW + 16)
            let itemY = recGridStartY - CGFloat(row) * (recItemH + 4)
            let itemRect = NSRect(x: itemX, y: itemY, width: recColW, height: recItemH)

            let isSelected = (selectedSection == 2 && selectedIndex == index)
            let isHovered = (hoveredSection == 2 && hoveredIndex == index)
            if isSelected || isHovered {
                NSColor(white: 1.0, alpha: isSelected ? 0.16 : 0.08).setFill()
                let rPill = NSBezierPath(roundedRect: itemRect, xRadius: 6, yRadius: 6)
                rPill.fill()
                if isHovered {
                    NSColor(white: 1.0, alpha: 0.10).setStroke()
                    let b = NSBezierPath(roundedRect: itemRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
                    b.lineWidth = 1
                    b.stroke()
                }
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 8, y: itemRect.midY - 12, width: 24, height: 24))

            let tStr = StartMenuText.fitted(item.title, font: NSFont.systemFont(ofSize: 11, weight: .bold), color: .white, maxWidth: itemRect.maxX - (itemRect.minX + 38) - 8)
            tStr.draw(at: NSPoint(x: itemRect.minX + 38, y: itemRect.midY - 1))

            let sStr = StartMenuText.fitted(item.subtitle, font: NSFont.systemFont(ofSize: 9), color: NSColor(white: 0.7, alpha: 1.0), maxWidth: itemRect.maxX - (itemRect.minX + 38) - 8)
            sStr.draw(at: NSPoint(x: itemRect.minX + 38, y: itemRect.midY - 14))
        }

        // 4. Section: Bottom Profile & Power Footer
        let footerRect = NSRect(x: 0, y: 0, width: bounds.width, height: 56)
        NSColor(white: 0.08, alpha: 0.98).setFill()
        let footerPath = NSBezierPath(roundedRect: footerRect, xRadius: 14, yRadius: 14)
        footerPath.fill()

        // User Avatar + Name
        let userEmblem = ProceduralIcons.shared.taskintoshIcon(size: 28)
        userEmblem.draw(in: NSRect(x: 36, y: 14, width: 28, height: 28))
        let userAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: NSColor.white]
        let userName = NSFullUserName().isEmpty ? NSUserName() : NSFullUserName()
        let userStr = NSAttributedString(string: userName, attributes: userAttrs)
        userStr.draw(at: NSPoint(x: 72, y: 20))

        // Power Button Icon
        let powerRect = NSRect(x: bounds.width - 68, y: 12, width: 32, height: 32)
        let isPowerActive = (selectedSection == 3 || hoveredSection == 3)
        if isPowerActive {
            NSColor(white: 1.0, alpha: hoveredSection == 3 ? 0.25 : 0.18).setFill()
            NSBezierPath(roundedRect: powerRect, xRadius: 6, yRadius: 6).fill()
        }
        let pAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: NSColor.white]
        let pStr = NSAttributedString(string: "⏻", attributes: pAttrs)
        pStr.draw(at: NSPoint(x: powerRect.midX - 7, y: powerRect.midY - 10))
    }

    private func drawSearchBarVisual() {
        let rect = searchBarRect
        NSColor(white: 0.18, alpha: 0.85).setFill()
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        path.fill()
        NSColor(white: 1.0, alpha: 0.10).setStroke()
        path.lineWidth = 1.0
        path.stroke()

        // Windows 11 Fluent magnifying glass on left
        let iconRect = NSRect(x: rect.minX + 10, y: rect.midY - 8, width: 16, height: 16)
        ProceduralIcons.shared.icon(for: .search, eraType: .centeredFlyout, size: 16).draw(in: iconRect)

        // NSTextField owns the placeholder rendering. Drawing it here as well
        // produces a doubled search prompt on an empty menu.
    }

    private func drawSearchResults() {
        let listRect = NSRect(x: 32, y: 56, width: bounds.width - 64, height: bounds.height - 124)
        let itemH: CGFloat = 36

        if searchResults.isEmpty {
            let noResAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.gray]
            let noResStr = NSAttributedString(string: "No results found", attributes: noResAttrs)
            noResStr.draw(at: NSPoint(x: listRect.minX + 16, y: listRect.midY))
            return
        }

        for (index, item) in searchResults.prefix(11).enumerated() {
            let itemRect = NSRect(x: listRect.minX, y: listRect.maxY - CGFloat(index + 1) * itemH, width: listRect.width, height: itemH)
            let isSelected = (selectedIndex == index)
            let isHovered = (hoveredSection == 0 && hoveredIndex == index)
            if isSelected || isHovered {
                NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 0.85).setFill()
                NSBezierPath(roundedRect: itemRect, xRadius: 6, yRadius: 6).fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 8, y: itemRect.midY - 10, width: 20, height: 20))

            let str = StartMenuText.fitted(item.title, font: NSFont.systemFont(ofSize: 11.5, weight: .medium), color: .white, maxWidth: itemRect.maxX - (itemRect.minX + 36) - 8)
            str.draw(at: NSPoint(x: itemRect.minX + 36, y: itemRect.midY - 2))

            let subStr = StartMenuText.fitted(item.subtitle, font: NSFont.systemFont(ofSize: 9), color: NSColor(white: 0.75, alpha: 1.0), maxWidth: itemRect.maxX - (itemRect.minX + 36) - 8)
            subStr.draw(at: NSPoint(x: itemRect.minX + 36, y: itemRect.midY - 14))
        }
    }

    override public func mouseDown(with event: NSEvent) {
        if isSearching {
            super.mouseDown(with: event)
            return
        }
        let loc = convert(event.locationInWindow, from: nil)
        let startX: CGFloat = 36
        let gridW: CGFloat = bounds.width - 72
        let colW: CGFloat = gridW / 6.0
        let rowH: CGFloat = 72

        for (index, _) in pinnedApps.enumerated() {
            let row = index / 6
            let col = index % 6
            let itemX = startX + CGFloat(col) * colW
            let itemY = pinnedGridStartY - CGFloat(row) * rowH
            let itemRect = NSRect(x: itemX + 3, y: itemY + 3, width: colW - 6, height: rowH - 6)
            if itemRect.contains(loc) {
                selectedSection = 1
                selectedIndex = index
                dragStartIndex = index
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
            let startX: CGFloat = 36
            let gridW: CGFloat = bounds.width - 72
            let colW: CGFloat = gridW / 6.0
            let rowH: CGFloat = 72

            var foundTarget: Int? = nil
            for (index, _) in pinnedApps.enumerated() {
                let row = index / 6
                let col = index % 6
                let itemX = startX + CGFloat(col) * colW
                let itemY = pinnedGridStartY - CGFloat(row) * rowH
                let itemRect = NSRect(x: itemX + 3, y: itemY + 3, width: colW - 6, height: rowH - 6)
                if itemRect.contains(loc) {
                    foundTarget = index
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
        let startX: CGFloat = 36
        let gridW: CGFloat = bounds.width - 72
        let colW: CGFloat = gridW / 6.0
        let rowH: CGFloat = 72

        for (index, app) in pinnedApps.enumerated() {
            let row = index / 6
            let col = index % 6
            let itemX = startX + CGFloat(col) * colW
            let itemY = pinnedGridStartY - CGFloat(row) * rowH
            let itemRect = NSRect(x: itemX + 3, y: itemY + 3, width: colW - 6, height: rowH - 6)
            if itemRect.contains(loc) {
                let menu = NSMenu(title: app.title)

                let openItem = NSMenuItem(title: "Open", action: #selector(contextOpenClicked(_:)), keyEquivalent: "")
                openItem.target = self
                openItem.tag = index
                menu.addItem(openItem)

                menu.addItem(NSMenuItem.separator())

                let unpinItem = NSMenuItem(title: "Unpin from Start", action: #selector(contextUnpinClicked(_:)), keyEquivalent: "")
                unpinItem.target = self
                unpinItem.representedObject = app.id
                menu.addItem(unpinItem)

                if index > 0 {
                    let moveFrontItem = NSMenuItem(title: "Move to Front", action: #selector(contextMoveFrontClicked(_:)), keyEquivalent: "")
                    moveFrontItem.target = self
                    moveFrontItem.tag = index
                    menu.addItem(moveFrontItem)
                }

                menu.addItem(NSMenuItem.separator())

                let resetItem = NSMenuItem(title: "Reset Pinned Apps", action: #selector(contextResetClicked), keyEquivalent: "")
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
        if idx >= 0 && idx < pinnedApps.count {
            onDismiss?()
            pinnedApps[idx].action()
        }
    }

    @objc private func contextUnpinClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        PinnedProgramsManager.shared.unpin(id: id, in: "org.taskintosh.era.windows11")
        setupContent()
        needsDisplay = true
    }

    @objc private func contextMoveFrontClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx > 0 else { return }
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: 0, in: "org.taskintosh.era.windows11")
        setupContent()
        needsDisplay = true
    }

    @objc private func contextResetClicked() {
        PinnedProgramsManager.shared.resetToDefaults(for: "org.taskintosh.era.windows11")
        setupContent()
        needsDisplay = true
    }

    override public func mouseUp(with event: NSEvent) {
        if isDragging {
            if let from = dragStartIndex, let to = dragCurrentTargetIndex, from != to {
                PinnedProgramsManager.shared.reorder(fromIndex: from, toIndex: to, in: "org.taskintosh.era.windows11")
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

        // Check Search Results
        if isSearching {
            let listRect = NSRect(x: 32, y: 56, width: bounds.width - 64, height: bounds.height - 124)
            let itemH: CGFloat = 36
            let idx = Int((listRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < min(11, searchResults.count) {
                onDismiss?()
                searchResults[idx].action()
            }
            return
        }

        // Check Power button
        let powerRect = NSRect(x: bounds.width - 68, y: 12, width: 32, height: 32)
        if powerRect.contains(loc) {
            onDismiss?()
            AppDelegate.shared?.openShutDownDialog()
            return
        }

        // Check Pinned Apps
        let startX: CGFloat = 36
        let gridW: CGFloat = bounds.width - 72
        let colW: CGFloat = gridW / 6.0
        let rowH: CGFloat = 72

        for (index, app) in pinnedApps.enumerated() {
            let row = index / 6
            let col = index % 6
            let itemX = startX + CGFloat(col) * colW
            let itemY = pinnedGridStartY - CGFloat(row) * rowH
            let itemRect = NSRect(x: itemX + 3, y: itemY + 3, width: colW - 6, height: rowH - 6)
            if itemRect.contains(loc) {
                onDismiss?()
                app.action()
                return
            }
        }

        // Check Recommended Items
        let recColW: CGFloat = (bounds.width - 72 - 16) / 2.0
        let recItemH: CGFloat = 42

        for (index, item) in recommendedItems.enumerated() {
            let col = index % 2
            let row = index / 2
            let itemX = startX + CGFloat(col) * (recColW + 16)
            let itemY = recGridStartY - CGFloat(row) * (recItemH + 4)
            let itemRect = NSRect(x: itemX, y: itemY, width: recColW, height: recItemH)
            if itemRect.contains(loc) {
                onDismiss?()
                item.action()
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

        if event.keyCode == 48 { // Tab
            selectedSection = (selectedSection + 1) % 4
            selectedIndex = 0
            needsDisplay = true
            return true
        } else if event.keyCode == 126 { // Up
            if selectedSection == 1 {
                selectedIndex = (selectedIndex - 6 + pinnedApps.count) % pinnedApps.count
            } else if selectedSection == 2 {
                selectedIndex = (selectedIndex - 2 + recommendedItems.count) % recommendedItems.count
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 125 { // Down
            if selectedSection == 1 {
                selectedIndex = (selectedIndex + 6) % pinnedApps.count
            } else if selectedSection == 2 {
                selectedIndex = (selectedIndex + 2) % recommendedItems.count
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 123 { // Left
            if selectedSection == 1 {
                selectedIndex = max(0, selectedIndex - 1)
            } else if selectedSection == 2 {
                selectedIndex = max(0, selectedIndex - 1)
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 124 { // Right
            if selectedSection == 1 {
                selectedIndex = min(pinnedApps.count - 1, selectedIndex + 1)
            } else if selectedSection == 2 {
                selectedIndex = min(recommendedItems.count - 1, selectedIndex + 1)
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 36 || event.keyCode == 76 { // Return
            if selectedSection == 1 && selectedIndex < pinnedApps.count {
                onDismiss?()
                pinnedApps[selectedIndex].action()
                return true
            } else if selectedSection == 2 && selectedIndex < recommendedItems.count {
                onDismiss?()
                recommendedItems[selectedIndex].action()
                return true
            } else if selectedSection == 3 {
                onDismiss?()
                AppDelegate.shared?.openShutDownDialog()
                return true
            }
        }
        return false
    }
}
