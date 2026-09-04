import AppKit
import TaskintoshKit

public final class Windows7MenuView: NSView, NSTextFieldDelegate {
    public var onDismiss: (() -> Void)?
    public var onCascadeRequest: ((String, NSRect) -> Void)?

    private let searchField = NSTextField()
    private var isSearching = false
    private var searchResults: [StartMenuSearchResult] = []
    private var selectedIndex: Int = 0
    private var selectedColumn: Int = 0 // 0: Left, 1: Right, 2: Power
    private var rightIndex: Int = 0

    public var isShowingAllPrograms = false
    public var allProgramsScrollOffset: CGFloat = 0
    public private(set) var maxProgramsScroll: CGFloat = 0

    private var hoveredColumn: Int? = nil
    private var hoveredIndex: Int? = nil
    private var isBottomButtonHovered: Bool = false
    private var isPowerHovered: Bool = false
    private var trackingArea: NSTrackingArea?

    // Drag-and-drop state for pinned items
    private var dragStartIndex: Int? = nil
    private var dragCurrentTargetIndex: Int? = nil
    private var isDragging: Bool = false
    private var dragMouseDownPoint: NSPoint? = nil

    public struct Win7Item {
        public let id: String
        public let title: String
        public let subtitle: String?
        public let icon: NSImage
        public let isBold: Bool
        public let action: () -> Void

        public init(
            id: String = UUID().uuidString,
            title: String,
            subtitle: String? = nil,
            icon: NSImage,
            isBold: Bool = false,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.isBold = isBold
            self.action = action
        }
    }

    public private(set) var leftItems: [Win7Item] = []
    public private(set) var rightItems: [Win7Item] = []
    public private(set) var installedApps: [CatalogApp] = []

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 420, height: 480))
        setupComponents()
        setupItems()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupComponents() {
        // Bottom search field
        searchField.frame = NSRect(x: 12, y: 12, width: 232, height: 26)
        searchField.placeholderString = "Search programs and files"
        searchField.font = NSFont.systemFont(ofSize: 11)
        searchField.delegate = self
        searchField.focusRingType = .exterior
        addSubview(searchField)
    }

    public func setupItems() {
        let locations = MacOSLocationsService.shared
        AppCatalog.shared.ensureLoadedSynchronously()
        self.installedApps = AppCatalog.shared.installedApps

        let icons = ProceduralIcons.shared
        let eraType = StartMenuType.twoColumnGlass

        let pinned = PinnedProgramsManager.shared.pinnedPrograms(for: "org.taskintosh.era.windows7")
        var items: [Win7Item] = []
        for (idx, p) in pinned.enumerated() {
            let isBold = (idx == 0)
            let sz: CGFloat = 24
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
                if p.id == "w7.safari" || p.iconType == "internet" {
                    NSWorkspace.shared.open(URL(string: "https://www.google.com")!)
                } else if p.id == "w7.actmon" {
                    locations.openActivityMonitor()
                } else if p.id == "w7.terminal" || p.iconType == "terminal" {
                    locations.openTerminal()
                } else if p.id == "w7.update" {
                    AppDelegate.shared?.openWindowsUpdate()
                } else if let path = p.path {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            }

            items.append(Win7Item(id: p.id, title: p.title, subtitle: p.subtitle, icon: icon, isBold: isBold, action: action))
        }
        leftItems = items

        rightItems = [
            Win7Item(title: NSUserName(), subtitle: "User Folder", icon: icons.icon(for: .user, eraType: eraType, size: 20), isBold: true) {
                locations.openURL(locations.homeURL)
            },
            Win7Item(title: "Documents", subtitle: nil, icon: icons.icon(for: .documents, eraType: eraType, size: 20), isBold: true) {
                locations.openURL(locations.documentsURL)
            },
            Win7Item(title: "Pictures", subtitle: nil, icon: icons.icon(for: .pictures, eraType: eraType, size: 20), isBold: false) {
                locations.openURL(locations.picturesURL)
            },
            Win7Item(title: "Music", subtitle: nil, icon: icons.icon(for: .music, eraType: eraType, size: 20), isBold: false) {
                locations.openURL(locations.homeURL.appendingPathComponent("Music"))
            },
            Win7Item(title: "Downloads", subtitle: nil, icon: icons.icon(for: .documents, eraType: eraType, size: 20), isBold: false) {
                locations.openURL(locations.downloadsURL)
            },
            Win7Item(title: "Computer", subtitle: nil, icon: icons.icon(for: .myComputer, eraType: eraType, size: 20), isBold: true) {
                locations.openURL(URL(fileURLWithPath: "/Volumes"))
            },
            Win7Item(title: "Control Panel", subtitle: nil, icon: icons.icon(for: .controlPanel, eraType: eraType, size: 20), isBold: false) {
                locations.openSystemSettings()
            },
            Win7Item(title: "Windows Update", subtitle: "System Updates", icon: icons.icon(for: .settings, eraType: eraType, size: 20), isBold: false) {
                AppDelegate.shared?.openWindowsUpdate()
            },
            Win7Item(title: "Devices and Printers", subtitle: nil, icon: icons.icon(for: .settings, eraType: eraType, size: 20), isBold: false) {
                locations.openSystemSettings()
            },
            Win7Item(title: "Default Programs", subtitle: nil, icon: icons.icon(for: .eraManager, eraType: eraType, size: 20), isBold: false) {
                AppDelegate.shared?.openEraManager()
            },
            Win7Item(title: "Help and Support", subtitle: nil, icon: icons.icon(for: .help, eraType: eraType, size: 20), isBold: false) {
                AppDelegate.shared?.openHelp()
            }
        ]
        recomputeAllProgramsScrollBounds()
        self.needsDisplay = true
    }

    private func recomputeAllProgramsScrollBounds() {
        let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
        let listHeight = leftColRect.height - 34 // reserve 34px for bottom back button
        let itemH: CGFloat = 30
        let totalH = CGFloat(installedApps.count) * itemH
        maxProgramsScroll = max(0, totalH - listHeight + 10)
        allProgramsScrollOffset = min(allProgramsScrollOffset, maxProgramsScroll)
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        searchField.frame = NSRect(x: 12, y: 12, width: 232, height: 26)
        recomputeAllProgramsScrollBounds()
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
        if isShowingAllPrograms && !isSearching {
            let loc = convert(event.locationInWindow, from: nil)
            let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
            if leftColRect.contains(loc) || event.window == nil {
                recomputeAllProgramsScrollBounds()
                allProgramsScrollOffset = min(maxProgramsScroll, max(0, allProgramsScrollOffset - event.deltaY * 8))
                needsDisplay = true
            }
        }
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
        let rightColRect = NSRect(x: 250, y: 46, width: bounds.width - 258, height: bounds.height - 54)
        let powerRect = NSRect(x: bounds.width - 130, y: 10, width: 118, height: 28)

        // 1. Power Button
        if powerRect.contains(loc) {
            if !isPowerHovered || hoveredColumn != 2 {
                isPowerHovered = true
                hoveredColumn = 2
                hoveredIndex = nil
                isBottomButtonHovered = false
                needsDisplay = true
            }
            return
        } else if isPowerHovered {
            isPowerHovered = false
            needsDisplay = true
        }

        // 2. Left Column
        if leftColRect.contains(loc) {
            let bottomBtnRect = NSRect(x: leftColRect.minX + 4, y: leftColRect.minY + 2, width: leftColRect.width - 8, height: 30)
            if bottomBtnRect.contains(loc) {
                if !isBottomButtonHovered || hoveredColumn != 0 {
                    isBottomButtonHovered = true
                    hoveredColumn = 0
                    hoveredIndex = nil
                    needsDisplay = true
                }
                return
            } else if isBottomButtonHovered {
                isBottomButtonHovered = false
                needsDisplay = true
            }

            if isShowingAllPrograms && !isSearching {
                let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: leftColRect.height - 34)
                if listRect.contains(loc) {
                    let itemH: CGFloat = 30
                    let clickY = listRect.maxY - loc.y + allProgramsScrollOffset
                    let idx = Int(clickY / itemH)
                    let validIdx = (idx >= 0 && idx < installedApps.count) ? idx : nil
                    if hoveredColumn != 0 || hoveredIndex != validIdx {
                        hoveredColumn = 0
                        hoveredIndex = validIdx
                        needsDisplay = true
                    }
                    return
                }
            } else {
                let itemsList = isSearching ? searchResults.map { $0.title } : leftItems.map { $0.title }
                let itemH = (leftColRect.height - 34) / CGFloat(max(1, itemsList.count))
                let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: leftColRect.height - 34)
                if listRect.contains(loc) {
                    let idx = Int((listRect.maxY - loc.y) / itemH)
                    let validIdx = (idx >= 0 && idx < itemsList.count) ? idx : nil
                    if hoveredColumn != 0 || hoveredIndex != validIdx {
                        hoveredColumn = 0
                        hoveredIndex = validIdx
                        needsDisplay = true
                    }
                    return
                }
            }
        }

        // 3. Right Column
        if rightColRect.contains(loc) {
            isBottomButtonHovered = false
            let itemH = rightColRect.height / CGFloat(max(1, rightItems.count))
            let idx = Int((rightColRect.maxY - loc.y) / itemH)
            let validIdx = (idx >= 0 && idx < rightItems.count) ? idx : nil
            if hoveredColumn != 1 || hoveredIndex != validIdx {
                hoveredColumn = 1
                hoveredIndex = validIdx
                needsDisplay = true
            }
            return
        }

        // Outside active zones
        if hoveredColumn != nil || hoveredIndex != nil || isBottomButtonHovered {
            hoveredColumn = nil
            hoveredIndex = nil
            isBottomButtonHovered = false
            needsDisplay = true
        }
    }

    override public func mouseExited(with event: NSEvent) {
        hoveredColumn = nil
        hoveredIndex = nil
        isBottomButtonHovered = false
        isPowerHovered = false
        needsDisplay = true
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 1. Aero Glass Gradient Background
        let glassGrad = NSGradient(colors: [
            NSColor(srgbRed: 0.08, green: 0.12, blue: 0.18, alpha: 0.94),
            NSColor(srgbRed: 0.14, green: 0.20, blue: 0.28, alpha: 0.92)
        ])
        glassGrad?.draw(in: bounds, angle: 90)

        // 3D Glass Outer Border
        NSColor(white: 1.0, alpha: 0.25).setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        path.stroke()

        // 2. Left Column (Translucent white glass plate)
        let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
        NSColor(white: 1.0, alpha: 0.92).setFill()
        let leftPath = NSBezierPath(roundedRect: leftColRect, xRadius: 4, yRadius: 4)
        leftPath.fill()

        // 3. Right Column (Dark translucent slate)
        let rightColRect = NSRect(x: 250, y: 46, width: bounds.width - 258, height: bounds.height - 54)

        // Draw Left Content (Search Results, All Programs list, or Standard Pinned Items)
        if isSearching {
            drawSearchResults(in: leftColRect)
        } else if isShowingAllPrograms {
            drawAllProgramsList(in: leftColRect)
        } else {
            drawStandardLeftItems(in: leftColRect)
        }

        // Draw Right Items
        let rightItemH: CGFloat = rightColRect.height / CGFloat(max(1, rightItems.count))
        for (index, item) in rightItems.enumerated() {
            let itemRect = NSRect(x: rightColRect.minX + 2, y: rightColRect.maxY - CGFloat(index + 1) * rightItemH, width: rightColRect.width - 4, height: rightItemH)
            let isSelected = (selectedColumn == 1 && rightIndex == index)
            let isHovered = (hoveredColumn == 1 && hoveredIndex == index)

            if isSelected || isHovered {
                NSColor(white: 1.0, alpha: isSelected ? 0.25 : 0.18).setFill()
                NSBezierPath(roundedRect: itemRect, xRadius: 3, yRadius: 3).fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 4, y: itemRect.midY - 8, width: 16, height: 16))
            let font = item.isBold ? NSFont.boldSystemFont(ofSize: 10) : NSFont.systemFont(ofSize: 10)
            let str = StartMenuText.fitted(item.title, font: font, color: .white, maxWidth: itemRect.maxX - (itemRect.minX + 26) - 4)
            str.draw(at: NSPoint(x: itemRect.minX + 26, y: itemRect.midY - 6))
        }

        // Bottom Power Button ("Shut Down" with Aero look)
        let powerRect = NSRect(x: bounds.width - 130, y: 10, width: 118, height: 28)
        let isPowerActive = (selectedColumn == 2 || isPowerHovered)
        let powerGrad = NSGradient(colors: [
            isPowerActive ? NSColor(srgbRed: 0.35, green: 0.58, blue: 0.95, alpha: 0.95) : NSColor(srgbRed: 0.18, green: 0.28, blue: 0.40, alpha: 0.8),
            isPowerActive ? NSColor(srgbRed: 0.20, green: 0.42, blue: 0.82, alpha: 0.95) : NSColor(srgbRed: 0.10, green: 0.18, blue: 0.28, alpha: 0.8)
        ])
        let powerPath = NSBezierPath(roundedRect: powerRect, xRadius: 4, yRadius: 4)
        powerGrad?.draw(in: powerPath, angle: 90)
        NSColor(white: 1.0, alpha: 0.35).setStroke()
        powerPath.stroke()

        let pAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.white]
        let pStr = NSAttributedString(string: "Shut Down ►", attributes: pAttrs)
        pStr.draw(at: NSPoint(x: powerRect.midX - 38, y: powerRect.midY - 7))

        // Draw Search Box
        drawSearchFieldVisual()
    }

    private func drawStandardLeftItems(in leftColRect: NSRect) {
        let contentH = leftColRect.height - 34
        let itemH = contentH / CGFloat(max(1, leftItems.count))

        for (index, item) in leftItems.enumerated() {
            let itemRect = NSRect(x: leftColRect.minX + 4, y: leftColRect.maxY - CGFloat(index + 1) * itemH, width: leftColRect.width - 8, height: itemH)
            let isSelected = (selectedColumn == 0 && selectedIndex == index)
            let isHovered = (hoveredColumn == 0 && hoveredIndex == index)

            if isSelected {
                let selGrad = NSGradient(colors: [
                    NSColor(srgbRed: 0.25, green: 0.58, blue: 0.95, alpha: 0.92),
                    NSColor(srgbRed: 0.15, green: 0.42, blue: 0.85, alpha: 0.92)
                ])
                let itemPath = NSBezierPath(roundedRect: itemRect, xRadius: 3, yRadius: 3)
                selGrad?.draw(in: itemPath, angle: 90)
                NSColor(srgbRed: 0.35, green: 0.65, blue: 1.0, alpha: 0.8).setStroke()
                itemPath.lineWidth = 1
                itemPath.stroke()
            } else if isHovered {
                let hoverGrad = NSGradient(colors: [
                    NSColor(srgbRed: 0.88, green: 0.94, blue: 1.0, alpha: 0.85),
                    NSColor(srgbRed: 0.72, green: 0.86, blue: 0.98, alpha: 0.85)
                ])
                let itemPath = NSBezierPath(roundedRect: itemRect, xRadius: 3, yRadius: 3)
                hoverGrad?.draw(in: itemPath, angle: 90)
                NSColor(srgbRed: 0.45, green: 0.72, blue: 0.96, alpha: 0.75).setStroke()
                itemPath.lineWidth = 1
                itemPath.stroke()

                // Specular top highlight line
                let topShine = NSRect(x: itemRect.minX + 2, y: itemRect.maxY - 1.5, width: itemRect.width - 4, height: 1)
                NSColor(white: 1.0, alpha: 0.7).setFill()
                topShine.fill()
            }

            // Insertion drop indicator during drag
            if isDragging && dragCurrentTargetIndex == index {
                NSColor(srgbRed: 0.20, green: 0.55, blue: 0.95, alpha: 1.0).setFill()
                NSRect(x: itemRect.minX + 2, y: itemRect.maxY - 1.5, width: itemRect.width - 4, height: 3).fill()
            }

            item.icon.draw(in: NSRect(x: itemRect.minX + 6, y: itemRect.midY - 11, width: 22, height: 22))
            let font = item.isBold ? NSFont.boldSystemFont(ofSize: 11) : NSFont.systemFont(ofSize: 11)
            let color = isSelected ? NSColor.white : NSColor.black
            let str = StartMenuText.fitted(item.title, font: font, color: color, maxWidth: itemRect.maxX - (itemRect.minX + 34) - 4)
            str.draw(at: NSPoint(x: itemRect.minX + 34, y: itemRect.midY - 7))
        }

        // Bottom "All Programs ►" Button
        let bottomBtnRect = NSRect(x: leftColRect.minX + 4, y: leftColRect.minY + 2, width: leftColRect.width - 8, height: 30)
        if isBottomButtonHovered {
            NSColor(srgbRed: 0.25, green: 0.55, blue: 0.95, alpha: 0.25).setFill()
            NSBezierPath(roundedRect: bottomBtnRect, xRadius: 3, yRadius: 3).fill()
        }
        ProceduralIcons.shared.programsIcon(size: 18).draw(in: NSRect(x: bottomBtnRect.minX + 6, y: bottomBtnRect.midY - 9, width: 18, height: 18))
        let btnAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let btnStr = NSAttributedString(string: "All Programs  ►", attributes: btnAttrs)
        btnStr.draw(at: NSPoint(x: bottomBtnRect.minX + 32, y: bottomBtnRect.midY - 7))
    }

    private func drawAllProgramsList(in leftColRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Top list area
        let listRect = NSRect(x: leftColRect.minX + 2, y: leftColRect.minY + 34, width: leftColRect.width - 4, height: leftColRect.height - 36)
        context.saveGState()
        context.clip(to: listRect)

        let itemH: CGFloat = 30
        for (index, app) in installedApps.enumerated() {
            let itemY = listRect.maxY - CGFloat(index + 1) * itemH + allProgramsScrollOffset
            let itemRect = NSRect(x: listRect.minX + 2, y: itemY, width: listRect.width - 10, height: itemH)
            if itemRect.maxY < listRect.minY || itemRect.minY > listRect.maxY { continue }

            let isHovered = (hoveredColumn == 0 && hoveredIndex == index)
            if isHovered {
                NSColor(srgbRed: 0.30, green: 0.60, blue: 0.95, alpha: 0.30).setFill()
                NSBezierPath(roundedRect: itemRect, xRadius: 3, yRadius: 3).fill()
            }

            app.icon.draw(in: NSRect(x: itemRect.minX + 6, y: itemRect.midY - 9, width: 18, height: 18))
            let str = StartMenuText.fitted(app.name, font: NSFont.systemFont(ofSize: 11), color: .black, maxWidth: itemRect.maxX - (itemRect.minX + 30) - 4)
            str.draw(at: NSPoint(x: itemRect.minX + 30, y: itemRect.midY - 7))
        }

        context.restoreGState()

        // Scrollbar if needed
        if maxProgramsScroll > 0 {
            let scrollTrack = NSRect(x: listRect.maxX - 4, y: listRect.minY + 2, width: 3, height: listRect.height - 4)
            NSColor.black.withAlphaComponent(0.08).setFill()
            scrollTrack.fill()

            let thumbH = max(24, (listRect.height / (listRect.height + maxProgramsScroll)) * scrollTrack.height)
            let thumbY = scrollTrack.maxY - thumbH - (allProgramsScrollOffset / maxProgramsScroll) * (scrollTrack.height - thumbH)
            let thumbRect = NSRect(x: scrollTrack.minX, y: thumbY, width: 3, height: thumbH)
            NSColor(srgbRed: 0.20, green: 0.50, blue: 0.85, alpha: 0.65).setFill()
            thumbRect.fill()
        }

        // Bottom "◄ Back" Button
        let bottomBtnRect = NSRect(x: leftColRect.minX + 4, y: leftColRect.minY + 2, width: leftColRect.width - 8, height: 30)
        if isBottomButtonHovered {
            NSColor(srgbRed: 0.25, green: 0.55, blue: 0.95, alpha: 0.25).setFill()
            NSBezierPath(roundedRect: bottomBtnRect, xRadius: 3, yRadius: 3).fill()
        }
        let backAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let backStr = NSAttributedString(string: "◄  Back", attributes: backAttrs)
        backStr.draw(at: NSPoint(x: bottomBtnRect.minX + 16, y: bottomBtnRect.midY - 7))
    }

    private func drawSearchResults(in leftColRect: NSRect) {
        if searchResults.isEmpty {
            let noResAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.gray]
            let noResStr = NSAttributedString(string: "No items match your search.", attributes: noResAttrs)
            noResStr.draw(at: NSPoint(x: leftColRect.minX + 16, y: leftColRect.midY))
        } else {
            let itemH: CGFloat = 32
            for (index, item) in searchResults.prefix(10).enumerated() {
                let itemRect = NSRect(x: leftColRect.minX + 4, y: leftColRect.maxY - CGFloat(index + 1) * itemH, width: leftColRect.width - 8, height: itemH)
                let isSelected = (selectedColumn == 0 && selectedIndex == index)
                let isHovered = (hoveredColumn == 0 && hoveredIndex == index)

                if isSelected || isHovered {
                    NSColor(srgbRed: 0.20, green: 0.50, blue: 0.95, alpha: 0.85).setFill()
                    NSBezierPath(roundedRect: itemRect, xRadius: 3, yRadius: 3).fill()
                }

                item.icon.draw(in: NSRect(x: itemRect.minX + 4, y: itemRect.midY - 9, width: 18, height: 18))
                let titleColor = (isSelected || isHovered) ? NSColor.white : NSColor.black
                let str = StartMenuText.fitted(item.title, font: NSFont.systemFont(ofSize: 11), color: titleColor, maxWidth: itemRect.maxX - (itemRect.minX + 28) - 4)
                str.draw(at: NSPoint(x: itemRect.minX + 28, y: itemRect.midY - 6))
            }
        }
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
        if leftColRect.contains(loc) && !isSearching && !isShowingAllPrograms {
            let contentH = leftColRect.height - 34
            let itemH = contentH / CGFloat(max(1, leftItems.count))
            let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: contentH)
            if listRect.contains(loc) {
                let idx = Int((listRect.maxY - loc.y) / itemH)
                if idx >= 0 && idx < leftItems.count {
                    selectedIndex = idx
                    selectedColumn = 0
                    dragStartIndex = idx
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
            let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
            let contentH = leftColRect.height - 34
            let itemH = contentH / CGFloat(max(1, leftItems.count))
            let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: contentH)
            let targetIdx = max(0, min(leftItems.count - 1, Int((listRect.maxY - loc.y) / itemH)))
            dragCurrentTargetIndex = targetIdx
            needsDisplay = true
        }
    }

    override public func rightMouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
        if leftColRect.contains(loc) && !isSearching && !isShowingAllPrograms {
            let contentH = leftColRect.height - 34
            let itemH = contentH / CGFloat(max(1, leftItems.count))
            let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: contentH)
            if listRect.contains(loc) {
                let idx = Int((listRect.maxY - loc.y) / itemH)
                if idx >= 0 && idx < leftItems.count {
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

                    if idx < leftItems.count - 1 {
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
        }
        super.rightMouseDown(with: event)
    }

    @objc private func contextOpenClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        if idx >= 0 && idx < leftItems.count {
            onDismiss?()
            leftItems[idx].action()
        }
    }

    @objc private func contextUnpinClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        PinnedProgramsManager.shared.unpin(id: id, in: "org.taskintosh.era.windows7")
        setupItems()
        needsDisplay = true
    }

    @objc private func contextMoveUpClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx > 0 else { return }
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: idx - 1, in: "org.taskintosh.era.windows7")
        setupItems()
        needsDisplay = true
    }

    @objc private func contextMoveDownClicked(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx < leftItems.count - 1 else { return }
        PinnedProgramsManager.shared.reorder(fromIndex: idx, toIndex: idx + 1, in: "org.taskintosh.era.windows7")
        setupItems()
        needsDisplay = true
    }

    @objc private func contextResetClicked() {
        PinnedProgramsManager.shared.resetToDefaults(for: "org.taskintosh.era.windows7")
        setupItems()
        needsDisplay = true
    }

    override public func mouseUp(with event: NSEvent) {
        if isDragging {
            if let from = dragStartIndex, let to = dragCurrentTargetIndex, from != to {
                PinnedProgramsManager.shared.reorder(fromIndex: from, toIndex: to, in: "org.taskintosh.era.windows7")
                setupItems()
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
        let powerRect = NSRect(x: bounds.width - 130, y: 10, width: 118, height: 28)

        if powerRect.contains(loc) {
            onDismiss?()
            AppDelegate.shared?.openShutDownDialog()
            return
        }

        let leftColRect = NSRect(x: 8, y: 46, width: 236, height: bounds.height - 54)
        let rightColRect = NSRect(x: 250, y: 46, width: bounds.width - 258, height: bounds.height - 54)

        if leftColRect.contains(loc) {
            let bottomBtnRect = NSRect(x: leftColRect.minX + 4, y: leftColRect.minY + 2, width: leftColRect.width - 8, height: 30)

            // Click on bottom button ("All Programs ►" or "◄ Back")
            if bottomBtnRect.contains(loc) {
                isShowingAllPrograms.toggle()
                allProgramsScrollOffset = 0
                needsDisplay = true
                return
            }

            if isSearching {
                let itemH: CGFloat = 32
                let idx = Int((leftColRect.maxY - loc.y) / itemH)
                if idx >= 0 && idx < min(10, searchResults.count) {
                    onDismiss?()
                    searchResults[idx].action()
                }
            } else if isShowingAllPrograms {
                let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: leftColRect.height - 34)
                if listRect.contains(loc) {
                    let itemH: CGFloat = 30
                    let clickY = listRect.maxY - loc.y + allProgramsScrollOffset
                    let idx = Int(clickY / itemH)
                    if idx >= 0 && idx < installedApps.count {
                        onDismiss?()
                        AppCatalog.shared.launch(installedApps[idx])
                    }
                }
            } else {
                let contentH = leftColRect.height - 34
                let itemH = contentH / CGFloat(max(1, leftItems.count))
                let listRect = NSRect(x: leftColRect.minX, y: leftColRect.minY + 34, width: leftColRect.width, height: contentH)
                if listRect.contains(loc) {
                    let idx = Int((listRect.maxY - loc.y) / itemH)
                    if idx >= 0 && idx < leftItems.count {
                        onDismiss?()
                        leftItems[idx].action()
                    }
                }
            }
        } else if rightColRect.contains(loc) {
            let itemH = rightColRect.height / CGFloat(max(1, rightItems.count))
            let idx = Int((rightColRect.maxY - loc.y) / itemH)
            if idx >= 0 && idx < rightItems.count {
                onDismiss?()
                rightItems[idx].action()
            }
        }
    }

    public func handleKeyDown(event: NSEvent) -> Bool {
        if event.keyCode == 48 { // Tab
            selectedColumn = (selectedColumn + 1) % 3
            needsDisplay = true
            return true
        } else if event.keyCode == 126 { // Up arrow
            if selectedColumn == 0 {
                let maxCount = isSearching ? searchResults.count : (isShowingAllPrograms ? installedApps.count : leftItems.count)
                if maxCount > 0 { selectedIndex = (selectedIndex - 1 + maxCount) % maxCount }
            } else if selectedColumn == 1 {
                rightIndex = (rightIndex - 1 + rightItems.count) % rightItems.count
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 125 { // Down arrow
            if selectedColumn == 0 {
                let maxCount = isSearching ? searchResults.count : (isShowingAllPrograms ? installedApps.count : leftItems.count)
                if maxCount > 0 { selectedIndex = (selectedIndex + 1) % maxCount }
            } else if selectedColumn == 1 {
                rightIndex = (rightIndex + 1) % rightItems.count
            }
            needsDisplay = true
            return true
        } else if event.keyCode == 123 { // Left arrow
            selectedColumn = 0
            needsDisplay = true
            return true
        } else if event.keyCode == 124 { // Right arrow
            selectedColumn = 1
            needsDisplay = true
            return true
        } else if event.keyCode == 36 || event.keyCode == 76 { // Return / Enter
            if selectedColumn == 0 {
                if isSearching && selectedIndex < searchResults.count {
                    onDismiss?()
                    searchResults[selectedIndex].action()
                } else if isShowingAllPrograms && selectedIndex < installedApps.count {
                    onDismiss?()
                    AppCatalog.shared.launch(installedApps[selectedIndex])
                } else if !isSearching && !isShowingAllPrograms && selectedIndex < leftItems.count {
                    onDismiss?()
                    leftItems[selectedIndex].action()
                }
            } else if selectedColumn == 1 && rightIndex < rightItems.count {
                onDismiss?()
                rightItems[rightIndex].action()
            } else if selectedColumn == 2 {
                onDismiss?()
                AppDelegate.shared?.openShutDownDialog()
            }
            return true
        }
        return false
    }

    private func drawSearchFieldVisual() {
        let fieldRect = NSRect(x: 12, y: 12, width: 232, height: 26)
        NSColor.white.setFill()
        let path = NSBezierPath(roundedRect: fieldRect, xRadius: 3, yRadius: 3)
        path.fill()
        NSColor(srgbRed: 0.2, green: 0.55, blue: 0.85, alpha: 0.9).setStroke()
        path.lineWidth = 1.0
        path.stroke()

        // Windows 7 blue magnifying glass icon on right
        let iconRect = NSRect(x: fieldRect.maxX - 22, y: fieldRect.midY - 8, width: 16, height: 16)
        ProceduralIcons.shared.icon(for: .search, eraType: .twoColumnGlass, size: 16).draw(in: iconRect)

        if searchField.stringValue.isEmpty {
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor(white: 0.55, alpha: 1.0)
            ]
            let str = NSAttributedString(string: "Search programs and files", attributes: placeholderAttrs)
            str.draw(at: NSPoint(x: fieldRect.minX + 8, y: fieldRect.midY - 7))
        }
    }
}
