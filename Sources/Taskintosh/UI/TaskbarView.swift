import TaskintoshKit
import AppKit
import Combine


public final class TaskbarView: NSView {
    private var cancellables = Set<AnyCancellable>()
    private var isStartButtonPressed: Bool = false
    private var taskButtonRects: [(TaskItem, NSRect)] = []
    private var quickLaunchRects: [(String, NSRect, () -> Void)] = []
    private var startButtonRect: NSRect = .zero
    private var trayRect: NSRect = .zero
    private var volumeIconRect: NSRect = .zero
    private var eraIconRect: NSRect = .zero
    private var clockRect: NSRect = .zero
    private var aeroPeekRect: NSRect = .zero
    private var actionCenterRect: NSRect = .zero
    private var taskScrollOffset: Int = 0
    private var scrollLeftRect: NSRect = .zero
    private var scrollRightRect: NSRect = .zero
    private var overflowRect: NSRect = .zero
    private var overflowItems: [TaskItem] = []

    // System Tray Controls & State
    private var networkIconRect: NSRect = .zero
    private var batteryIconRect: NSRect = .zero
    private var chevronRect: NSRect = .zero
    private var quickSettingsRect: NSRect = .zero
    private var showDesktopSliceRect: NSRect = .zero
    private var hoveredTrayControl: TrayControl?
    private var activeTrayControl: TrayControl?
    private var trackingArea: NSTrackingArea?

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupSubscriptions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        RunningAppWatcher.shared.$taskItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        RunningAppWatcher.shared.$frontmostPID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        EraManager.shared.$activeEra
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.taskScrollOffset = 0
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        SystemMonitor.shared.$timeString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        SystemMonitor.shared.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        SystemMonitor.shared.$volumeLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        SystemMonitor.shared.$isNetworkConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Native AppKit Context Menu Provider
    override public func menu(for event: NSEvent) -> NSMenu? {
        let loc = convert(event.locationInWindow, from: nil)

        // 1. Check if right-clicking a taskbar application button
        for (item, rect) in taskButtonRects {
            if rect.contains(loc) {
                return createTaskContextMenu(for: item)
            }
        }

        // 2. Otherwise return the taskbar background context menu
        let autoHide = AppDelegate.shared?.isAutoHideEnabled ?? false
        return TaskbarContextMenu(target: self, autoHideEnabled: autoHide)
    }

    private func createTaskContextMenu(for item: TaskItem) -> NSMenu {
        let menu = NSMenu(title: item.title)
        menu.autoenablesItems = false

        let restoreItem = NSMenuItem(title: "Restore / Bring to Front", action: #selector(taskActionRestore(_:)), keyEquivalent: "")
        restoreItem.target = self
        restoreItem.representedObject = item
        menu.addItem(restoreItem)

        let minimizeItem = NSMenuItem(title: "Minimize", action: #selector(taskActionMinimize(_:)), keyEquivalent: "")
        minimizeItem.target = self
        minimizeItem.representedObject = item
        menu.addItem(minimizeItem)

        menu.addItem(NSMenuItem.separator())

        let closeItem = NSMenuItem(title: "Close", action: #selector(taskActionClose(_:)), keyEquivalent: "")
        closeItem.target = self
        closeItem.representedObject = item
        menu.addItem(closeItem)

        return menu
    }

    // MARK: - Action Handlers (Target / Action)
    @objc public func taskActionRestore(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        RunningAppWatcher.shared.restoreApp(item)
    }

    @objc public func taskActionMinimize(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        RunningAppWatcher.shared.minimizeApp(item)
    }

    @objc public func taskActionClose(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        RunningAppWatcher.shared.terminateApp(item)
    }

    @objc public func showDesktopClicked() {
        RunningAppWatcher.shared.minimizeAllWindows()
    }

    @objc public func taskManagerClicked() {
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }

    @objc public func windowsUpdateClicked() {
        AppDelegate.shared?.openWindowsUpdate()
    }

    @objc public func toggleAutoHideClicked() {
        AppDelegate.shared?.toggleAutoHide()
    }

    @objc public func openEraManagerClicked() {
        AppDelegate.shared?.openEraManager()
    }

    @objc public func setTaskbarSizePresetClicked(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let preset = TaskbarSizePreset(rawValue: raw) else { return }
        UserDefaults.standard.set(preset.rawValue, forKey: "TaskbarSizePreset")
        AppDelegate.shared?.refreshTaskbarGeometry()
        needsDisplay = true
    }

    // MARK: - Taskbar Hit Testing & Geometry Inspection

    public func rectForTaskItem(_ item: TaskItem) -> NSRect? {
        return taskButtonRects.first(where: { $0.0.id == item.id || $0.0.pid == item.pid })?.1
    }

    public var currentStartButtonRect: NSRect { startButtonRect }
    public var currentTrayRect: NSRect { trayRect }
    public var currentTaskButtonRects: [(TaskItem, NSRect)] { taskButtonRects }

    public func findGuaranteedEmptyBackgroundPoint() -> NSPoint? {
        let testY = bounds.height > 6 ? bounds.midY : bounds.height / 2.0

        // 1. Scan horizontally across bounds
        var x = max(0, startButtonRect.maxX + 4)
        while x < bounds.maxX - 4 {
            let pt = NSPoint(x: x, y: testY)
            if !startButtonRect.contains(pt) &&
               !trayRect.contains(pt) &&
               !aeroPeekRect.contains(pt) &&
               !showDesktopSliceRect.contains(pt) &&
               !quickLaunchRects.contains(where: { $0.1.contains(pt) }) &&
               !taskButtonRects.contains(where: { $0.1.contains(pt) }) &&
               bounds.contains(pt) {
                return pt
            }
            x += 6
        }

        // 2. Scan vertically near top border above task buttons
        let topY = bounds.height - 2
        var topX = max(0, startButtonRect.maxX + 4)
        while topX < bounds.maxX - 4 {
            let topPt = NSPoint(x: topX, y: topY)
            if !startButtonRect.contains(topPt) &&
               !trayRect.contains(topPt) &&
               !taskButtonRects.contains(where: { $0.1.contains(topPt) }) &&
               bounds.contains(topPt) {
                return topPt
            }
            topX += 8
        }
        return nil
    }

    // MARK: - Mouse Event Routing
    override public func mouseDown(with event: NSEvent) {
        // Intercept Control-Click (standard macOS secondary click)
        if event.modifierFlags.contains(.control) {
            if let contextMenu = self.menu(for: event) {
                NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
            }
            return
        }

        let loc = convert(event.locationInWindow, from: nil)

        // 1. Start Button Click
        if startButtonRect.contains(loc) {
            isStartButtonPressed = true
            needsDisplay = true
            toggleStartMenu()
            return
        }

        // 2. Quick Launch Clicks
        for (_, rect, action) in quickLaunchRects {
            if rect.contains(loc) {
                action()
                return
            }
        }

        // 3. Task Button Click
        for (item, rect) in taskButtonRects {
            if rect.contains(loc) {
                let era = EraManager.shared.activeEra
                RunningAppWatcher.shared.handleTaskItemClick(item, behavior: era.behaviors.clickActiveAppAction)
                return
            }
        }

        // 4. Scroll & Overflow Controls
        if scrollLeftRect.contains(loc) {
            taskScrollOffset = max(0, taskScrollOffset - 1)
            needsDisplay = true
            return
        }
        if scrollRightRect.contains(loc) {
            taskScrollOffset += 1
            needsDisplay = true
            return
        }
        if overflowRect.contains(loc) {
            showOverflowMenu(at: loc)
            return
        }

        // 5. Aero Peek / Show Desktop Slice (far right edge)
        if (aeroPeekRect.width > 0 && aeroPeekRect.contains(loc)) || (showDesktopSliceRect.width > 0 && showDesktopSliceRect.contains(loc)) {
            RunningAppWatcher.shared.minimizeAllWindows()
            return
        }

        // 6. System Tray Item Clicks
        let era = EraManager.shared.activeEra
        if era.behaviors.unifiedSystemTrayCluster {
            if quickSettingsRect.width > 0 && quickSettingsRect.contains(loc) {
                toggleTrayControl(.quickSettings, anchor: quickSettingsRect)
                return
            }
        }

        if volumeIconRect.width > 0 && volumeIconRect.contains(loc) {
            toggleTrayControl(.volume, anchor: volumeIconRect)
            return
        }

        if networkIconRect.width > 0 && networkIconRect.contains(loc) {
            toggleTrayControl(.network, anchor: networkIconRect)
            return
        }

        if batteryIconRect.width > 0 && batteryIconRect.contains(loc) {
            toggleTrayControl(.battery, anchor: batteryIconRect)
            return
        }

        if clockRect.width > 0 && clockRect.contains(loc) {
            toggleTrayControl(.clock, anchor: clockRect)
            return
        }

        if actionCenterRect.width > 0 && actionCenterRect.contains(loc) {
            toggleTrayControl(.actionCenter, anchor: actionCenterRect)
            return
        }

        if chevronRect.width > 0 && chevronRect.contains(loc) {
            toggleTrayControl(.actionCenter, anchor: chevronRect)
            return
        }

        if eraIconRect.width > 0 && eraIconRect.contains(loc) {
            AppDelegate.shared?.openEraManager()
            return
        }
    }

    override public func mouseUp(with event: NSEvent) {
        if isStartButtonPressed {
            isStartButtonPressed = false
            needsDisplay = true
        }
    }

    override public func rightMouseDown(with event: NSEvent) {
        if let contextMenu = self.menu(for: event) {
            NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
        }
    }

    // MARK: - Drawing & Layout Engine
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let era = EraManager.shared.activeEra
        let theme = era.theme
        let layout = era.layout

        // 1. Draw Taskbar Background
        drawBackground(theme: theme, layout: layout)

        if layout.taskbarStyle == .verticalShelf {
            drawVerticalShelf(theme: theme, layout: layout, era: era)
            return
        }

        let btnH: CGFloat = max(18, bounds.height - 6)

        // 2. Compute Aero Peek / Show Desktop slice if configured
        var rightMargin: CGFloat = 4
        if layout.showDesktopButton == .farRightPeek {
            let peekW: CGFloat = 12
            aeroPeekRect = NSRect(x: bounds.width - peekW - 1, y: 1, width: peekW, height: bounds.height - 2)
            drawAeroPeek(in: aeroPeekRect, theme: theme)
            showDesktopSliceRect = .zero
            rightMargin = peekW + 4
        } else if theme.startMenuType == .tileLauncher || theme.startMenuType == .modernTiles || theme.startMenuType == .hybridMenu || theme.startMenuType == .centeredFlyout {
            let sliceW: CGFloat = 5
            showDesktopSliceRect = NSRect(x: bounds.width - sliceW, y: 1, width: sliceW, height: bounds.height - 2)
            drawShowDesktopSlice(in: showDesktopSliceRect, theme: theme)
            aeroPeekRect = .zero
            rightMargin = sliceW + 4
        } else {
            aeroPeekRect = .zero
            showDesktopSliceRect = .zero
        }

        // 3. Draw System Tray on the right
        let trayW: CGFloat = computeTrayWidth(era: era)
        trayRect = NSRect(x: bounds.width - trayW - rightMargin, y: 3, width: trayW, height: btnH)
        drawSystemTray(in: trayRect, era: era)

        // 4. Draw Start Button & Running Task Buttons
        let items = RunningAppWatcher.shared.taskItems
        taskButtonRects.removeAll()
        quickLaunchRects.removeAll()
        let tasksEndX = trayRect.minX - 6

        if layout.alignment == .center {
            // Windows 11: Start Button is part of the centered cluster
            let buttonSize: CGFloat = min(btnH, 40)
            let spacing: CGFloat = 6
            let startW = layout.startButtonWidth
            let tasksCount = CGFloat(items.count)
            let totalClusterWidth = startW + (tasksCount > 0 ? spacing : 0) + tasksCount * buttonSize + CGFloat(max(0, items.count - 1)) * spacing
            let clusterStartX = max(layout.paddingHorizontal + 2, bounds.midX - totalClusterWidth / 2.0)

            startButtonRect = NSRect(x: clusterStartX, y: (bounds.height - btnH) / 2.0, width: startW, height: btnH)
            drawStartButton(in: startButtonRect, era: era)

            let tasksStartX = startButtonRect.maxX + spacing
            if !items.isEmpty {
                drawCenteredTaskButtons(items: items, startX: tasksStartX, endX: tasksEndX, btnH: btnH, era: era)
            }
        } else {
            // Left-aligned eras (Windows 95, XP, 7, 8, 10)
            let startW = layout.startButtonWidth
            let startX = layout.paddingHorizontal + 2
            startButtonRect = NSRect(x: startX, y: (bounds.height - btnH) / 2.0, width: startW, height: btnH)
            drawStartButton(in: startButtonRect, era: era)

            var tasksStartX = startButtonRect.maxX + 6
            if layout.quickLaunchEnabled {
                tasksStartX = drawQuickLaunch(startingAt: tasksStartX, height: btnH, theme: theme)
            }

            let availableWidth = max(0, tasksEndX - tasksStartX)
            if !items.isEmpty && availableWidth > 20 {
                drawStandardTaskButtons(items: items, startX: tasksStartX, endX: tasksEndX, btnH: btnH, era: era)
            }
        }
    }

    private func drawBackground(theme: EraVisualTheme, layout: EraLayoutConfig) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        switch theme.translucencyStyle {
        case .glass:
            // Aero Glass Gradient with specular line
            let bgColors = [
                theme.backgroundColor.withAlphaComponent(0.85).cgColor,
                theme.backgroundColor.withAlphaComponent(0.65).cgColor
            ] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: bounds.maxY), end: CGPoint(x: 0, y: bounds.minY), options: [])
            }
            // Specular glass highlight line at top
            NSColor.white.withAlphaComponent(0.35).setFill()
            NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()

        case .acrylic, .mica:
            theme.backgroundColor.withAlphaComponent(0.88).setFill()
            bounds.fill()
            NSColor.white.withAlphaComponent(0.08).setFill()
            NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()

        case .opaque:
            theme.backgroundColor.setFill()
            bounds.fill()
            if theme.bevelStyle == .classic3D {
                theme.lightHighlightColor.setFill()
                NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()
            }
        }
    }

    private func drawVerticalShelf(theme: EraVisualTheme, layout: EraLayoutConfig, era: EraPackage) {
        // 1. Top Start / Shelf Tile
        let topSize: CGFloat = min(bounds.width - 4, 60)
        startButtonRect = NSRect(x: 2, y: bounds.height - topSize - 2, width: topSize, height: topSize)
        drawStartButton(in: startButtonRect, era: era)

        // 2. Running Application Tiles
        let items = RunningAppWatcher.shared.taskItems
        taskButtonRects.removeAll()
        let tileSize: CGFloat = min(bounds.width - 4, 56)
        let spacing: CGFloat = 4

        for (index, item) in items.enumerated() {
            let y = startButtonRect.minY - spacing - CGFloat(index + 1) * (tileSize + spacing) + spacing
            if y < 50 { break }

            let itemRect = NSRect(x: 2, y: y, width: tileSize, height: tileSize)
            taskButtonRects.append((item, itemRect))
            renderTaskButton(item: item, in: itemRect, era: era)
        }

        // 3. Bottom Clock / System Tile
        trayRect = NSRect(x: 2, y: 4, width: bounds.width - 4, height: 44)
        drawSystemTray(in: trayRect, era: era)
    }

    private func drawStartButton(in rect: NSRect, era: EraPackage) {
        let theme = era.theme
        let isPressed = isStartButtonPressed || StartMenuWindow.shared.isVisible
        let offset: CGFloat = isPressed ? 1.0 : 0.0

        switch theme.startButtonStyle {
        case .lunaPill:
            // Windows XP curved green Start button
            let pillColor = isPressed
                ? NSColor(srgbRed: 0.18, green: 0.55, blue: 0.15, alpha: 1.0)
                : NSColor(srgbRed: 0.22, green: 0.65, blue: 0.2, alpha: 1.0)
            pillColor.setFill()
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            path.fill()
            NSColor(srgbRed: 0.1, green: 0.4, blue: 0.1, alpha: 1.0).setStroke()
            path.stroke()

            let emblem = ProceduralIcons.shared.lunaStartEmblem(size: 16)
            emblem.draw(in: NSRect(x: rect.minX + 6 + offset, y: rect.midY - 8 - offset, width: 16, height: 16))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.boldFont(size: 11),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: theme.startButtonText, attributes: attrs)
            str.draw(at: NSPoint(x: rect.minX + 26 + offset, y: rect.midY - 7 - offset))

        case .aeroOrb:
            // Circular 3D glass Aero Orb
            let orbSize: CGFloat = min(rect.height + 4, rect.width)
            let orbRect = NSRect(x: rect.minX + 2, y: rect.midY - orbSize / 2.0, width: orbSize, height: orbSize)
            let orb = ProceduralIcons.shared.aeroStartOrb(size: orbSize)
            orb.draw(in: orbRect)

        case .flatTiles:
            // Windows 8/10 Flat Tiles
            if isPressed {
                theme.accentColor.withAlphaComponent(0.3).setFill()
                rect.fill()
            }
            let tiles = ProceduralIcons.shared.flatStartTiles(size: 16, color: isPressed ? theme.accentColor : .white)
            tiles.draw(in: NSRect(x: rect.midX - 8, y: rect.midY - 8, width: 16, height: 16))

        case .win11Centered:
            // Windows 11 Modern Logo
            if isPressed {
                NSColor.white.withAlphaComponent(0.12).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            }
            let emblem = ProceduralIcons.shared.win11StartEmblem(size: 20)
            emblem.draw(in: NSRect(x: rect.midX - 10, y: rect.midY - 10, width: 20, height: 20))

        case .appleMenu:
            // Classic Mac OS Apple Menu
            if isPressed {
                NSColor.black.setFill()
                rect.fill()
            }
            let apple = ProceduralIcons.shared.appleRetroLogo(size: 16)
            apple.draw(in: NSRect(x: rect.midX - 8, y: rect.midY - 8, width: 16, height: 16))

        case .nextIcon:
            let cube = ProceduralIcons.shared.nextCubeLogo(size: 20)
            cube.draw(in: NSRect(x: rect.midX - 10, y: rect.midY - 10, width: 20, height: 20))

        case .beLogo:
            let logo = ProceduralIcons.shared.beLogo(size: 20)
            logo.draw(in: NSRect(x: rect.midX - 10, y: rect.midY - 10, width: 20, height: 20))

        case .amigaTitle:
            // Amiga Workbench title
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: "Workbench Screen", attributes: attrs)
            str.draw(at: NSPoint(x: rect.minX + 4, y: rect.midY - 6))

        case .classicRect:
            // Classic Windows 95/98/2000 Bevel
            theme.surfaceColor.setFill()
            rect.fill()
            if isPressed {
                BevelRenderer.shared.drawSunkenBevel(in: rect, theme: theme)
            } else {
                BevelRenderer.shared.drawRaisedBevel(in: rect, theme: theme)
            }

            let emblem = era.image(named: "start_emblem") ?? ProceduralIcons.shared.startEmblem(size: 16)
            emblem.draw(in: NSRect(x: rect.minX + 4 + offset, y: rect.midY - 8 - offset, width: 16, height: 16))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.boldFont(size: 11),
                .foregroundColor: theme.textColor
            ]
            let str = NSAttributedString(string: theme.startButtonText, attributes: attrs)
            str.draw(at: NSPoint(x: rect.minX + 23 + offset, y: rect.midY - 7 - offset))

        case .classicGreen:
            // Windows 95 Green Start button with 3D bevels
            let greenFace = isPressed
                ? NSColor(srgbRed: 0.14, green: 0.45, blue: 0.20, alpha: 1.0)
                : NSColor(srgbRed: 0.18, green: 0.58, blue: 0.25, alpha: 1.0)
            greenFace.setFill()
            rect.fill()
            if isPressed {
                BevelRenderer.shared.drawSunkenBevel(in: rect, theme: theme)
            } else {
                BevelRenderer.shared.drawRaisedBevel(in: rect, theme: theme)
            }

            let emblem = era.image(named: "start_emblem") ?? ProceduralIcons.shared.startEmblem(size: 16)
            emblem.draw(in: NSRect(x: rect.minX + 4 + offset, y: rect.midY - 8 - offset, width: 16, height: 16))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.boldFont(size: 11),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: theme.startButtonText, attributes: attrs)
            str.draw(at: NSPoint(x: rect.minX + 23 + offset, y: rect.midY - 7 - offset))
        }
    }

    private func drawQuickLaunch(startingAt x: CGFloat, height: CGFloat, theme: EraVisualTheme) -> CGFloat {
        var curX = x
        // Draw vertical grip divider
        theme.shadowColor.setFill()
        NSRect(x: curX, y: 4, width: 1, height: height - 2).fill()
        theme.lightHighlightColor.setFill()
        NSRect(x: curX + 1, y: 4, width: 1, height: height - 2).fill()
        curX += 5

        let itemSize: CGFloat = min(20, height)
        let y = (bounds.height - itemSize) / 2.0

        // 1. Show Desktop
        let showDesktopRect = NSRect(x: curX, y: y, width: itemSize, height: itemSize)
        ProceduralIcons.shared.showDesktopIcon(size: 16).draw(in: showDesktopRect.insetBy(dx: 2, dy: 2))
        quickLaunchRects.append(("Show Desktop", showDesktopRect, { [weak self] in self?.showDesktopClicked() }))
        curX += itemSize + 2

        // 2. Internet Browser
        let browserRect = NSRect(x: curX, y: y, width: itemSize, height: itemSize)
        ProceduralIcons.shared.internetIcon(size: 16).draw(in: browserRect.insetBy(dx: 2, dy: 2))
        quickLaunchRects.append(("Browser", browserRect, {
            if let url = URL(string: "https://www.apple.com") { NSWorkspace.shared.open(url) }
        }))
        curX += itemSize + 2

        // 3. Terminal
        let termRect = NSRect(x: curX, y: y, width: itemSize, height: itemSize)
        ProceduralIcons.shared.terminalIcon(size: 16).draw(in: termRect.insetBy(dx: 2, dy: 2))
        quickLaunchRects.append(("Terminal", termRect, {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
        }))
        curX += itemSize + 4

        // Ending divider
        theme.shadowColor.setFill()
        NSRect(x: curX, y: 4, width: 1, height: height - 2).fill()
        theme.lightHighlightColor.setFill()
        NSRect(x: curX + 1, y: 4, width: 1, height: height - 2).fill()
        curX += 6

        return curX
    }

    private func drawStandardTaskButtons(items: [TaskItem], startX: CGFloat, endX: CGFloat, btnH: CGFloat, era: EraPackage) {
        let layout = era.layout
        let availableWidth = max(0, endX - startX)
        guard availableWidth > 20, !items.isEmpty else { return }

        let spacing = layout.itemSpacing

        if layout.buttonStyle == .iconOnly || layout.buttonStyle == .pill {
            // Icon-only Superbar (Win 7) or Pill layout
            let buttonSize = btnH
            let totalNeeded = CGFloat(items.count) * buttonSize + CGFloat(items.count - 1) * spacing

            if totalNeeded <= availableWidth {
                for (index, item) in items.enumerated() {
                    let x = startX + CGFloat(index) * (buttonSize + spacing)
                    let itemRect = NSRect(x: x, y: (bounds.height - btnH) / 2.0, width: buttonSize, height: btnH)
                    taskButtonRects.append((item, itemRect))
                    renderTaskButton(item: item, in: itemRect, era: era)
                }
            } else {
                // Overflow in icon-only mode
                let overflowW: CGFloat = 28
                let maxVisible = max(1, Int((availableWidth - overflowW - spacing) / (buttonSize + spacing)))
                let visibleItems = Array(items.prefix(maxVisible))
                let remainingItems = Array(items.dropFirst(maxVisible))

                for (index, item) in visibleItems.enumerated() {
                    let x = startX + CGFloat(index) * (buttonSize + spacing)
                    let itemRect = NSRect(x: x, y: (bounds.height - btnH) / 2.0, width: buttonSize, height: btnH)
                    taskButtonRects.append((item, itemRect))
                    renderTaskButton(item: item, in: itemRect, era: era)
                }

                let overflowX = startX + CGFloat(visibleItems.count) * (buttonSize + spacing)
                let overflowRect = NSRect(x: overflowX, y: (bounds.height - btnH) / 2.0, width: overflowW, height: btnH)
                drawOverflowButton(in: overflowRect, overflowItems: remainingItems, era: era)
            }
            return
        }

        // Standard / Tile wide text buttons (Win 95, Win XP, Win 8, Win 10)
        let minW = max(130, layout.taskButtonMinWidth)
        let maxW = max(minW, layout.taskButtonMaxWidth)
        let totalSpacing = CGFloat(items.count - 1) * spacing
        let naturalWidth = (availableWidth - totalSpacing) / CGFloat(items.count)

        if naturalWidth >= minW {
            // All items fit comfortably at or above readable minimum width
            let buttonWidth = min(maxW, naturalWidth)
            for (index, item) in items.enumerated() {
                let x = startX + CGFloat(index) * (buttonWidth + spacing)
                let itemRect = NSRect(x: x, y: (bounds.height - btnH) / 2.0, width: buttonWidth, height: btnH)
                taskButtonRects.append((item, itemRect))
                renderTaskButton(item: item, in: itemRect, era: era)
            }
        } else {
            // Insufficient space to show all buttons at minimum width: apply era-specific overflow
            switch layout.overflowStrategy {
            case .scrollButtons:
                // Windows 95: Classic scroll controls (◀ / ▶)
                let scrollGadgetW: CGFloat = 36
                let usableTasksW = availableWidth - scrollGadgetW - spacing
                let buttonWidth = minW
                let visibleCount = max(1, Int(usableTasksW / (buttonWidth + spacing)))

                let maxOffset = max(0, items.count - visibleCount)
                taskScrollOffset = max(0, min(taskScrollOffset, maxOffset))

                let visibleSlice = items.dropFirst(taskScrollOffset).prefix(visibleCount)
                for (index, item) in visibleSlice.enumerated() {
                    let x = startX + CGFloat(index) * (buttonWidth + spacing)
                    let itemRect = NSRect(x: x, y: (bounds.height - btnH) / 2.0, width: buttonWidth, height: btnH)
                    taskButtonRects.append((item, itemRect))
                    renderTaskButton(item: item, in: itemRect, era: era)
                }

                let scrollRect = NSRect(x: startX + CGFloat(visibleSlice.count) * (buttonWidth + spacing), y: (bounds.height - btnH) / 2.0, width: scrollGadgetW, height: btnH)
                drawScrollControls(in: scrollRect, canScrollLeft: taskScrollOffset > 0, canScrollRight: taskScrollOffset < maxOffset, era: era)

            case .grouping, .chevronMenu:
                // Windows XP / Win 8 / Win 10: Overflow Chevron button (>>)
                let overflowBtnW: CGFloat = 28
                let usableTasksW = availableWidth - overflowBtnW - spacing
                let buttonWidth = minW
                let visibleCount = max(1, Int(usableTasksW / (buttonWidth + spacing)))

                let visibleItems = Array(items.prefix(visibleCount))
                let remainingItems = Array(items.dropFirst(visibleCount))

                for (index, item) in visibleItems.enumerated() {
                    let x = startX + CGFloat(index) * (buttonWidth + spacing)
                    let itemRect = NSRect(x: x, y: (bounds.height - btnH) / 2.0, width: buttonWidth, height: btnH)
                    taskButtonRects.append((item, itemRect))
                    renderTaskButton(item: item, in: itemRect, era: era)
                }

                let overflowX = startX + CGFloat(visibleItems.count) * (buttonWidth + spacing)
                let overflowRect = NSRect(x: overflowX, y: (bounds.height - btnH) / 2.0, width: overflowBtnW, height: btnH)
                drawOverflowButton(in: overflowRect, overflowItems: remainingItems, era: era)

            case .iconOnly:
                let buttonSize = btnH
                for (index, item) in items.enumerated() {
                    let x = startX + CGFloat(index) * (buttonSize + spacing)
                    if x + buttonSize > endX { break }
                    let itemRect = NSRect(x: x, y: (bounds.height - btnH) / 2.0, width: buttonSize, height: btnH)
                    taskButtonRects.append((item, itemRect))
                    renderTaskButton(item: item, in: itemRect, era: era)
                }
            }
        }
    }

    private func drawCenteredTaskButtons(items: [TaskItem], startX: CGFloat, endX: CGFloat, btnH: CGFloat, era: EraPackage) {
        let buttonSize: CGFloat = min(btnH, 40)
        let spacing: CGFloat = 6
        let availableWidth = max(0, endX - startX)
        let totalWidth = CGFloat(items.count) * buttonSize + CGFloat(max(0, items.count - 1)) * spacing

        if totalWidth <= availableWidth {
            for (index, item) in items.enumerated() {
                let x = startX + CGFloat(index) * (buttonSize + spacing)
                let itemRect = NSRect(x: x, y: (bounds.height - buttonSize) / 2.0, width: buttonSize, height: buttonSize)
                taskButtonRects.append((item, itemRect))
                renderTaskButton(item: item, in: itemRect, era: era)
            }
        } else {
            let overflowW: CGFloat = 32
            let maxVisible = max(1, Int((availableWidth - overflowW - spacing) / (buttonSize + spacing)))
            let visibleItems = Array(items.prefix(maxVisible))
            let remainingItems = Array(items.dropFirst(maxVisible))

            for (index, item) in visibleItems.enumerated() {
                let x = startX + CGFloat(index) * (buttonSize + spacing)
                let itemRect = NSRect(x: x, y: (bounds.height - buttonSize) / 2.0, width: buttonSize, height: buttonSize)
                taskButtonRects.append((item, itemRect))
                renderTaskButton(item: item, in: itemRect, era: era)
            }

            let overflowX = startX + CGFloat(visibleItems.count) * (buttonSize + spacing)
            let overflowRect = NSRect(x: overflowX, y: (bounds.height - buttonSize) / 2.0, width: overflowW, height: buttonSize)
            drawOverflowButton(in: overflowRect, overflowItems: remainingItems, era: era)
        }
    }

    private func drawScrollControls(in rect: NSRect, canScrollLeft: Bool, canScrollRight: Bool, era: EraPackage) {
        let theme = era.theme
        let halfW = rect.width / 2.0
        scrollLeftRect = NSRect(x: rect.minX, y: rect.minY, width: halfW, height: rect.height)
        scrollRightRect = NSRect(x: rect.minX + halfW, y: rect.minY, width: halfW, height: rect.height)

        // Left button (◀)
        theme.surfaceColor.setFill()
        scrollLeftRect.fill()
        BevelRenderer.shared.drawRaisedBevel(in: scrollLeftRect, theme: theme)
        let leftArrowAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: canScrollLeft ? theme.textColor : theme.shadowColor
        ]
        let leftStr = NSAttributedString(string: "◀", attributes: leftArrowAttrs)
        let leftSize = leftStr.size()
        leftStr.draw(at: NSPoint(x: scrollLeftRect.midX - leftSize.width / 2.0, y: scrollLeftRect.midY - leftSize.height / 2.0))

        // Right button (▶)
        theme.surfaceColor.setFill()
        scrollRightRect.fill()
        BevelRenderer.shared.drawRaisedBevel(in: scrollRightRect, theme: theme)
        let rightArrowAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: canScrollRight ? theme.textColor : theme.shadowColor
        ]
        let rightStr = NSAttributedString(string: "▶", attributes: rightArrowAttrs)
        let rightSize = rightStr.size()
        rightStr.draw(at: NSPoint(x: scrollRightRect.midX - rightSize.width / 2.0, y: scrollRightRect.midY - rightSize.height / 2.0))
    }

    private func drawOverflowButton(in rect: NSRect, overflowItems: [TaskItem], era: EraPackage) {
        self.overflowRect = rect
        self.overflowItems = overflowItems
        let theme = era.theme

        switch theme.bevelStyle {
        case .classic3D:
            theme.surfaceColor.setFill()
            rect.fill()
            BevelRenderer.shared.drawRaisedBevel(in: rect, theme: theme)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.boldFont(size: 10),
                .foregroundColor: theme.textColor
            ]
            let str = NSAttributedString(string: ">>", attributes: attrs)
            let strSize = str.size()
            str.draw(at: NSPoint(x: rect.midX - strSize.width / 2.0, y: rect.midY - strSize.height / 2.0))

        case .flat:
            if theme.startButtonStyle == .lunaPill {
                // Windows XP Chevron pill
                NSColor(srgbRed: 0.18, green: 0.42, blue: 0.85, alpha: 1.0).setFill()
                let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
                path.fill()
                NSColor(srgbRed: 0.35, green: 0.65, blue: 0.98, alpha: 1.0).setStroke()
                path.stroke()
            } else if theme.startMenuType == .centeredFlyout {
                // Windows 11 rounded overflow capsule
                NSColor.white.withAlphaComponent(0.12).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
            } else {
                // Windows 8 / 10 flat plate
                theme.surfaceColor.setFill()
                rect.fill()
            }

            let symbol = theme.startMenuType == .centeredFlyout ? "•••" : ">>"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.boldFont(size: 10),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: symbol, attributes: attrs)
            let strSize = str.size()
            str.draw(at: NSPoint(x: rect.midX - strSize.width / 2.0, y: rect.midY - strSize.height / 2.0))

        case .etched:
            theme.surfaceColor.setFill()
            rect.fill()
        }
    }

    private func showOverflowMenu(at loc: NSPoint) {
        guard !overflowItems.isEmpty else { return }
        let menu = NSMenu(title: "Running Applications")
        menu.autoenablesItems = false
        for item in overflowItems {
            let menuItem = NSMenuItem(title: item.title, action: #selector(overflowItemSelected(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = item
            if let icon = item.icon {
                menuItem.image = icon
            }
            if item.isActive {
                menuItem.state = .on
            }
            menu.addItem(menuItem)
        }
        menu.popUp(positioning: nil, at: loc, in: self)
    }

    @objc private func overflowItemSelected(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        let era = EraManager.shared.activeEra
        RunningAppWatcher.shared.handleTaskItemClick(item, behavior: era.behaviors.clickActiveAppAction)
    }

    private func renderTaskButton(item: TaskItem, in rect: NSRect, era: EraPackage) {
        let theme = era.theme
        let layout = era.layout
        let isFront = item.isActive
        let offset: CGFloat = (isFront && theme.bevelStyle == .classic3D) ? 1.0 : 0.0

        switch layout.buttonStyle {
        case .pill:
            // Windows 11 Rounded Icon Plate
            let plateRect = rect.insetBy(dx: 1, dy: 1)
            if isFront {
                NSColor.white.withAlphaComponent(0.12).setFill()
                NSBezierPath(roundedRect: plateRect, xRadius: 6, yRadius: 6).fill()
                // Centered 16px bottom indicator pill
                theme.accentColor.setFill()
                let dotRect = NSRect(x: rect.midX - 8, y: rect.minY + 2, width: 16, height: 3)
                NSBezierPath(roundedRect: dotRect, xRadius: 1.5, yRadius: 1.5).fill()
            } else {
                // Inactive running app indicator dot
                NSColor.white.withAlphaComponent(0.5).setFill()
                let dotRect = NSRect(x: rect.midX - 2, y: rect.minY + 2, width: 4, height: 3)
                NSBezierPath(roundedRect: dotRect, xRadius: 1.5, yRadius: 1.5).fill()
            }
            if let icon = item.icon {
                icon.draw(in: NSRect(x: rect.midX - 11, y: rect.midY - 11, width: 22, height: 22))
            }

        case .iconOnly:
            // Windows 7 Superbar 3D Square Glass Plate
            if isFront {
                theme.accentColor.withAlphaComponent(0.35).setFill()
                let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
                path.fill()
                NSColor.white.withAlphaComponent(0.3).setStroke()
                path.stroke()
                // Specular top highlight line
                NSColor.white.withAlphaComponent(0.5).setFill()
                NSRect(x: rect.minX + 2, y: rect.maxY - 2, width: rect.width - 4, height: 1).fill()
            } else {
                NSColor.white.withAlphaComponent(0.10).setFill()
                let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
                path.fill()
            }
            if let icon = item.icon {
                icon.draw(in: NSRect(x: rect.midX - 11, y: rect.midY - 11, width: 22, height: 22))
            }

        case .tile:
            // Windows 8 Flat Sharp Modern Tiles
            if isFront {
                NSColor(srgbRed: 0.0, green: 0.45, blue: 0.70, alpha: 1.0).setFill()
                rect.fill()
                theme.accentColor.setFill()
                NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 2).fill()
            } else {
                theme.surfaceColor.setFill()
                rect.fill()
            }

            if let icon = item.icon {
                icon.draw(in: NSRect(x: rect.minX + 8, y: rect.midY - 8, width: 16, height: 16))
            }

            let font = isFront ? theme.boldFont(size: 11) : theme.font(size: 11)
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .paragraphStyle: style
            ]
            let titleX = rect.minX + 28
            let titleW = max(0, rect.maxX - titleX - 8)
            let titleRect = NSRect(x: titleX, y: rect.midY - 7, width: titleW, height: 15)
            item.title.draw(in: titleRect, withAttributes: attrs)

        case .standard:
            // Windows 95 / XP / 10 Wide Readable Buttons
            if theme.accentIndicatorStyle == .bottomLine {
                // Windows 10 Dark Acrylic Plate with 2px Accent Line
                if isFront {
                    NSColor(srgbRed: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).setFill()
                    rect.fill()
                    theme.accentColor.setFill()
                    NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 2).fill()
                } else {
                    theme.surfaceColor.setFill()
                    rect.fill()
                    NSColor.gray.withAlphaComponent(0.6).setFill()
                    NSRect(x: rect.midX - 4, y: rect.minY, width: 8, height: 1).fill()
                }
            } else if theme.accentIndicatorStyle == .glowPill {
                // Windows XP Luna Glowing Button Plate
                if isFront {
                    NSColor(srgbRed: 0.09, green: 0.26, blue: 0.66, alpha: 1.0).setFill()
                    let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
                    path.fill()
                    NSColor(srgbRed: 0.39, green: 0.65, blue: 0.97, alpha: 1.0).setStroke()
                    path.lineWidth = 1.0
                    path.stroke()
                } else {
                    theme.surfaceColor.setFill()
                    let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
                    path.fill()
                    NSColor(srgbRed: 0.20, green: 0.45, blue: 0.88, alpha: 1.0).setStroke()
                    path.lineWidth = 1.0
                    path.stroke()
                }
            } else {
                // Windows 95 Classic 3D Bevel with 50% Active Dither
                if isFront {
                    if theme.ditherActiveButton {
                        BevelRenderer.shared.drawActiveDither(in: rect, theme: theme)
                    } else {
                        theme.surfaceColor.setFill()
                        rect.fill()
                    }
                    BevelRenderer.shared.drawSunkenBevel(in: rect, theme: theme)
                } else {
                    theme.surfaceColor.setFill()
                    rect.fill()
                    BevelRenderer.shared.drawRaisedBevel(in: rect, theme: theme)
                }
            }

            if let icon = item.icon {
                icon.draw(in: NSRect(x: rect.minX + 6 + offset, y: rect.midY - 8 - offset, width: 16, height: 16))
            }

            let font = isFront ? theme.boldFont(size: 11) : theme.font(size: 11)
            let textColor = isFront ? theme.activeTextColor : theme.textColor
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byTruncatingTail

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: style
            ]

            let titleX = rect.minX + 26 + offset
            let titleW = max(0, rect.maxX - titleX - 6 - offset)
            let titleRect = NSRect(x: titleX, y: rect.midY - 7 - offset, width: titleW, height: 15)
            item.title.draw(in: titleRect, withAttributes: attrs)
        }
    }

    private func computeTrayWidth(era: EraPackage) -> CGFloat {
        switch era.theme.startMenuType {
        case .classicOneColumn:
            return 82
        case .twoColumnXP:
            return 126
        case .twoColumnGlass:
            return 165
        case .tileLauncher, .modernTiles:
            return 145
        case .hybridMenu:
            return SystemMonitor.shared.hasBattery ? 196 : 176
        case .centeredFlyout:
            return SystemMonitor.shared.hasBattery ? 192 : 172
        default:
            return 120
        }
    }

    private func drawShowDesktopSlice(in rect: NSRect, theme: EraVisualTheme) {
        NSColor.white.withAlphaComponent(0.15).setFill()
        rect.fill()
        NSColor.white.withAlphaComponent(0.35).setFill()
        NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height).fill()
    }

    private func drawAeroPeek(in rect: NSRect, theme: EraVisualTheme) {
        NSColor.white.withAlphaComponent(0.18).setFill()
        rect.fill()
        NSColor.white.withAlphaComponent(0.4).setFill()
        NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height).fill()
    }

    private func drawSystemTray(in rect: NSRect, era: EraPackage) {
        let theme = era.theme
        let isMuted = SystemMonitor.shared.isMuted
        let isConnected = SystemMonitor.shared.isNetworkConnected
        let isWiFi = SystemMonitor.shared.isWiFi
        let hasBattery = SystemMonitor.shared.hasBattery

        // Reset tracking rects
        volumeIconRect = .zero
        networkIconRect = .zero
        batteryIconRect = .zero
        chevronRect = .zero
        actionCenterRect = .zero
        quickSettingsRect = .zero
        clockRect = .zero
        eraIconRect = .zero

        switch theme.startMenuType {
        case .classicOneColumn:
            // ----------------------------------------------------
            // Windows 95 Classic Sunken Tray
            // ----------------------------------------------------
            theme.surfaceColor.setFill()
            rect.fill()
            BevelRenderer.shared.drawSunkenBevel(in: rect, theme: theme)

            // Volume Speaker
            volumeIconRect = NSRect(x: rect.minX + 4, y: rect.midY - 7, width: 16, height: 14)
            if hoveredTrayControl == .volume || activeTrayControl == .volume {
                theme.surfaceColor.setFill()
                volumeIconRect.insetBy(dx: -1, dy: -1).fill()
                BevelRenderer.shared.drawSunkenBevel(in: volumeIconRect.insetBy(dx: -1, dy: -1), theme: theme)
            }
            ProceduralIcons.shared.soundIcon(size: 14, color: .black, isMuted: isMuted).draw(in: volumeIconRect)

            // Era Switcher Icon
            eraIconRect = NSRect(x: rect.minX + 22, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.taskintoshIcon(size: 14).draw(in: eraIconRect)

            // Clock
            let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
            let font = theme.font(size: 10)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
            let str = NSAttributedString(string: timeStr, attributes: attrs)
            let strSize = str.size()
            clockRect = NSRect(x: rect.maxX - strSize.width - 6, y: rect.midY - strSize.height / 2.0, width: strSize.width, height: strSize.height)
            if hoveredTrayControl == .clock || activeTrayControl == .clock {
                theme.surfaceColor.setFill()
                clockRect.insetBy(dx: -2, dy: -1).fill()
                BevelRenderer.shared.drawSunkenBevel(in: clockRect.insetBy(dx: -2, dy: -1), theme: theme)
            }
            str.draw(at: clockRect.origin)

        case .twoColumnXP:
            // ----------------------------------------------------
            // Windows XP Luna Tray Well
            // ----------------------------------------------------
            NSColor(srgbRed: 0.08, green: 0.22, blue: 0.60, alpha: 1.0).setFill()
            let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            path.fill()
            NSColor(srgbRed: 0.05, green: 0.15, blue: 0.40, alpha: 1.0).setStroke()
            path.stroke()

            // Chevron < (hidden icons)
            chevronRect = NSRect(x: rect.minX + 4, y: rect.midY - 6, width: 12, height: 12)
            ProceduralIcons.shared.trayChevronIcon(size: 10, color: .white, isUp: false).draw(in: chevronRect)

            // Network Monitors
            networkIconRect = NSRect(x: rect.minX + 18, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .network || activeTrayControl == .network {
                NSColor.white.withAlphaComponent(0.15).setFill()
                NSBezierPath(roundedRect: networkIconRect.insetBy(dx: -2, dy: -2), xRadius: 2, yRadius: 2).fill()
            }
            ProceduralIcons.shared.networkIcon(size: 14, color: .white, isConnected: isConnected, isWinXP: true).draw(in: networkIconRect)

            // Volume Speaker
            volumeIconRect = NSRect(x: rect.minX + 36, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .volume || activeTrayControl == .volume {
                NSColor.white.withAlphaComponent(0.15).setFill()
                NSBezierPath(roundedRect: volumeIconRect.insetBy(dx: -2, dy: -2), xRadius: 2, yRadius: 2).fill()
            }
            ProceduralIcons.shared.soundIcon(size: 14, color: .white, isMuted: isMuted).draw(in: volumeIconRect)

            // Era Switcher Icon
            eraIconRect = NSRect(x: rect.minX + 54, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.taskintoshIcon(size: 14).draw(in: eraIconRect)

            // Live Clock
            let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
            let font = theme.font(size: 10)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
            let str = NSAttributedString(string: timeStr, attributes: attrs)
            let strSize = str.size()
            clockRect = NSRect(x: rect.maxX - strSize.width - 6, y: rect.midY - strSize.height / 2.0, width: strSize.width, height: strSize.height)
            if hoveredTrayControl == .clock || activeTrayControl == .clock {
                NSColor.white.withAlphaComponent(0.15).setFill()
                NSBezierPath(roundedRect: clockRect.insetBy(dx: -3, dy: -2), xRadius: 2, yRadius: 2).fill()
            }
            str.draw(at: clockRect.origin)

        case .twoColumnGlass:
            // ----------------------------------------------------
            // Windows 7 Aero Glass Tray
            // ----------------------------------------------------
            NSColor.white.withAlphaComponent(0.08).setFill()
            let aeroPath = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            aeroPath.fill()
            NSColor.white.withAlphaComponent(0.2).setStroke()
            aeroPath.stroke()

            // Chevron ^
            chevronRect = NSRect(x: rect.minX + 4, y: rect.midY - 6, width: 12, height: 12)
            ProceduralIcons.shared.trayChevronIcon(size: 10, color: .white, isUp: true).draw(in: chevronRect)

            // Action Center Flag
            actionCenterRect = NSRect(x: rect.minX + 20, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.actionCenterFlagIcon(size: 14, color: .white).draw(in: actionCenterRect)

            // Network Icon
            networkIconRect = NSRect(x: rect.minX + 38, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .network || activeTrayControl == .network {
                NSColor.white.withAlphaComponent(0.18).setFill()
                NSBezierPath(roundedRect: networkIconRect.insetBy(dx: -2, dy: -2), xRadius: 2, yRadius: 2).fill()
            }
            ProceduralIcons.shared.networkIcon(size: 14, color: .white, isConnected: isConnected, isWiFi: isWiFi).draw(in: networkIconRect)

            // Volume Speaker
            volumeIconRect = NSRect(x: rect.minX + 56, y: rect.midY - 8, width: 16, height: 16)
            if hoveredTrayControl == .volume || activeTrayControl == .volume {
                NSColor.white.withAlphaComponent(0.18).setFill()
                NSBezierPath(roundedRect: volumeIconRect.insetBy(dx: -2, dy: -2), xRadius: 2, yRadius: 2).fill()
            }
            ProceduralIcons.shared.soundIcon(size: 15, color: .white, isMuted: isMuted).draw(in: volumeIconRect)

            // Era Switcher Icon
            eraIconRect = NSRect(x: rect.minX + 76, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.taskintoshIcon(size: 14).draw(in: eraIconRect)

            // Stacked 2-line Clock & Date
            let clockW: CGFloat = 62
            clockRect = NSRect(x: rect.maxX - clockW - 4, y: rect.minY + 2, width: clockW, height: rect.height - 4)
            if hoveredTrayControl == .clock || activeTrayControl == .clock {
                NSColor.white.withAlphaComponent(0.18).setFill()
                NSBezierPath(roundedRect: clockRect, xRadius: 3, yRadius: 3).fill()
            }
            let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
            let dateStr = SystemMonitor.shared.dateShortString.isEmpty ? "9/3/2026" : SystemMonitor.shared.dateShortString

            let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.white]
            let dateAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.white.withAlphaComponent(0.85)]

            let tAttrStr = NSAttributedString(string: timeStr, attributes: timeAttrs)
            let dAttrStr = NSAttributedString(string: dateStr, attributes: dateAttrs)

            tAttrStr.draw(at: NSPoint(x: clockRect.midX - tAttrStr.size().width / 2.0, y: clockRect.midY + 1))
            dAttrStr.draw(at: NSPoint(x: clockRect.midX - dAttrStr.size().width / 2.0, y: clockRect.midY - 12))

        case .tileLauncher, .modernTiles:
            // ----------------------------------------------------
            // Windows 8.1 Modern Slate Tray
            // ----------------------------------------------------
            NSColor.white.withAlphaComponent(0.06).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()

            chevronRect = NSRect(x: rect.minX + 4, y: rect.midY - 6, width: 12, height: 12)
            ProceduralIcons.shared.trayChevronIcon(size: 10, color: .white, isUp: true).draw(in: chevronRect)

            networkIconRect = NSRect(x: rect.minX + 20, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .network || activeTrayControl == .network {
                NSColor.white.withAlphaComponent(0.15).setFill()
                networkIconRect.insetBy(dx: -2, dy: -2).fill()
            }
            ProceduralIcons.shared.networkIcon(size: 14, color: .white, isConnected: isConnected, isWiFi: isWiFi).draw(in: networkIconRect)

            volumeIconRect = NSRect(x: rect.minX + 38, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .volume || activeTrayControl == .volume {
                NSColor.white.withAlphaComponent(0.15).setFill()
                volumeIconRect.insetBy(dx: -2, dy: -2).fill()
            }
            ProceduralIcons.shared.soundIcon(size: 14, color: .white, isMuted: isMuted).draw(in: volumeIconRect)

            eraIconRect = NSRect(x: rect.minX + 56, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.taskintoshIcon(size: 14).draw(in: eraIconRect)

            let clockW: CGFloat = 62
            clockRect = NSRect(x: rect.maxX - clockW - 4, y: rect.minY + 2, width: clockW, height: rect.height - 4)
            if hoveredTrayControl == .clock || activeTrayControl == .clock {
                NSColor.white.withAlphaComponent(0.15).setFill()
                clockRect.fill()
            }
            let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
            let dateStr = SystemMonitor.shared.dateShortString.isEmpty ? "9/3/2026" : SystemMonitor.shared.dateShortString

            let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.white]
            let dateAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.white.withAlphaComponent(0.85)]
            let tAttrStr = NSAttributedString(string: timeStr, attributes: timeAttrs)
            let dAttrStr = NSAttributedString(string: dateStr, attributes: dateAttrs)

            tAttrStr.draw(at: NSPoint(x: clockRect.midX - tAttrStr.size().width / 2.0, y: clockRect.midY + 1))
            dAttrStr.draw(at: NSPoint(x: clockRect.midX - dAttrStr.size().width / 2.0, y: clockRect.midY - 12))

        case .hybridMenu:
            // ----------------------------------------------------
            // Windows 10 Dark Acrylic Tray
            // ----------------------------------------------------
            NSColor.white.withAlphaComponent(0.04).setFill()
            rect.fill()

            var curX = rect.minX + 4
            chevronRect = NSRect(x: curX, y: rect.midY - 6, width: 12, height: 12)
            ProceduralIcons.shared.trayChevronIcon(size: 10, color: .white, isUp: true).draw(in: chevronRect)
            curX += 16

            networkIconRect = NSRect(x: curX, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .network || activeTrayControl == .network {
                NSColor.white.withAlphaComponent(0.12).setFill()
                networkIconRect.insetBy(dx: -2, dy: -2).fill()
            }
            ProceduralIcons.shared.networkIcon(size: 14, color: .white, isConnected: isConnected, isWiFi: isWiFi).draw(in: networkIconRect)
            curX += 18

            volumeIconRect = NSRect(x: curX, y: rect.midY - 7, width: 15, height: 14)
            if hoveredTrayControl == .volume || activeTrayControl == .volume {
                NSColor.white.withAlphaComponent(0.12).setFill()
                volumeIconRect.insetBy(dx: -2, dy: -2).fill()
            }
            ProceduralIcons.shared.soundIcon(size: 14, color: .white, isMuted: isMuted).draw(in: volumeIconRect)
            curX += 18

            if hasBattery {
                batteryIconRect = NSRect(x: curX, y: rect.midY - 7, width: 16, height: 14)
                if hoveredTrayControl == .battery || activeTrayControl == .battery {
                    NSColor.white.withAlphaComponent(0.12).setFill()
                    batteryIconRect.insetBy(dx: -2, dy: -2).fill()
                }
                ProceduralIcons.shared.batteryIcon(size: 14, color: .white, percentage: SystemMonitor.shared.batteryPercentage, isCharging: SystemMonitor.shared.isCharging).draw(in: batteryIconRect)
                curX += 20
            }

            eraIconRect = NSRect(x: curX, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.taskintoshIcon(size: 14).draw(in: eraIconRect)

            actionCenterRect = NSRect(x: rect.maxX - 16, y: rect.midY - 7, width: 14, height: 14)
            if hoveredTrayControl == .actionCenter || activeTrayControl == .actionCenter {
                NSColor.white.withAlphaComponent(0.12).setFill()
                actionCenterRect.insetBy(dx: -2, dy: -2).fill()
            }
            ProceduralIcons.shared.actionCenterIcon(size: 14).draw(in: actionCenterRect)

            let clockW: CGFloat = 62
            clockRect = NSRect(x: actionCenterRect.minX - clockW - 4, y: rect.minY + 2, width: clockW, height: rect.height - 4)
            if hoveredTrayControl == .clock || activeTrayControl == .clock {
                NSColor.white.withAlphaComponent(0.12).setFill()
                clockRect.fill()
            }
            let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
            let dateStr = SystemMonitor.shared.dateShortString.isEmpty ? "9/3/2026" : SystemMonitor.shared.dateShortString

            let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.white]
            let dateAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.white.withAlphaComponent(0.85)]
            let tAttrStr = NSAttributedString(string: timeStr, attributes: timeAttrs)
            let dAttrStr = NSAttributedString(string: dateStr, attributes: dateAttrs)

            tAttrStr.draw(at: NSPoint(x: clockRect.midX - tAttrStr.size().width / 2.0, y: clockRect.midY + 1))
            dAttrStr.draw(at: NSPoint(x: clockRect.midX - dAttrStr.size().width / 2.0, y: clockRect.midY - 12))

        case .centeredFlyout:
            // ----------------------------------------------------
            // Windows 11 Grouped Quick Settings & Date Pills
            // ----------------------------------------------------
            chevronRect = NSRect(x: rect.minX + 4, y: rect.midY - 6, width: 12, height: 12)
            ProceduralIcons.shared.trayChevronIcon(size: 10, color: .white, isUp: true).draw(in: chevronRect)

            // Grouped Quick Settings Pill
            let pillW: CGFloat = hasBattery ? 62 : 44
            quickSettingsRect = NSRect(x: rect.minX + 18, y: rect.midY - 14, width: pillW, height: 28)
            if activeTrayControl == .quickSettings {
                NSColor.white.withAlphaComponent(0.16).setFill()
                NSBezierPath(roundedRect: quickSettingsRect, xRadius: 6, yRadius: 6).fill()
            } else if hoveredTrayControl == .quickSettings {
                NSColor.white.withAlphaComponent(0.08).setFill()
                NSBezierPath(roundedRect: quickSettingsRect, xRadius: 6, yRadius: 6).fill()
            }

            var pillX = quickSettingsRect.minX + 6
            networkIconRect = NSRect(x: pillX, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.networkIcon(size: 14, color: .white, isConnected: isConnected, isWiFi: isWiFi).draw(in: networkIconRect)
            pillX += 18

            volumeIconRect = NSRect(x: pillX, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.soundIcon(size: 14, color: .white, isMuted: isMuted).draw(in: volumeIconRect)
            pillX += 18

            if hasBattery {
                batteryIconRect = NSRect(x: pillX, y: rect.midY - 7, width: 14, height: 14)
                ProceduralIcons.shared.batteryIcon(size: 14, color: .white, percentage: SystemMonitor.shared.batteryPercentage, isCharging: SystemMonitor.shared.isCharging).draw(in: batteryIconRect)
            }

            // Stacked Clock & Date Pill
            let clockW: CGFloat = 66
            clockRect = NSRect(x: quickSettingsRect.maxX + 4, y: rect.midY - 14, width: clockW, height: 28)
            if activeTrayControl == .clock {
                NSColor.white.withAlphaComponent(0.16).setFill()
                NSBezierPath(roundedRect: clockRect, xRadius: 6, yRadius: 6).fill()
            } else if hoveredTrayControl == .clock {
                NSColor.white.withAlphaComponent(0.08).setFill()
                NSBezierPath(roundedRect: clockRect, xRadius: 6, yRadius: 6).fill()
            }

            let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
            let dateStr = SystemMonitor.shared.dateShortString.isEmpty ? "9/3/2026" : SystemMonitor.shared.dateShortString

            let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: NSColor.white]
            let dateAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.white.withAlphaComponent(0.85)]
            let tAttrStr = NSAttributedString(string: timeStr, attributes: timeAttrs)
            let dAttrStr = NSAttributedString(string: dateStr, attributes: dateAttrs)

            tAttrStr.draw(at: NSPoint(x: clockRect.midX - tAttrStr.size().width / 2.0, y: clockRect.midY + 1))
            dAttrStr.draw(at: NSPoint(x: clockRect.midX - dAttrStr.size().width / 2.0, y: clockRect.midY - 12))

            // Era Switcher Icon
            eraIconRect = NSRect(x: rect.maxX - 16, y: rect.midY - 7, width: 14, height: 14)
            ProceduralIcons.shared.taskintoshIcon(size: 14).draw(in: eraIconRect)

        default:
            break
        }
    }

    private func toggleStartMenu() {
        if TrayFlyoutWindow.shared.isVisible {
            TrayFlyoutWindow.shared.hideFlyout()
            activeTrayControl = nil
        }
        let now = Date().timeIntervalSinceReferenceDate
        if StartMenuWindow.shared.isVisible {
            StartMenuWindow.shared.hideMenu()
        } else if now - StartMenuWindow.shared.lastDismissalTimestamp < 0.25 {
            isStartButtonPressed = false
        } else {
            let winOrigin = window?.frame.origin ?? .zero
            let menuRect = NSRect(x: winOrigin.x + startButtonRect.minX, y: winOrigin.y, width: startButtonRect.width, height: bounds.height)
            StartMenuWindow.shared.showAbove(rect: menuRect) { [weak self] in
                self?.isStartButtonPressed = false
                self?.needsDisplay = true
            }
        }
        needsDisplay = true
    }

    private func screenRect(for localRect: NSRect) -> NSRect {
        guard let win = window else { return localRect }
        return win.convertToScreen(localRect)
    }

    private func toggleTrayControl(_ control: TrayControl, anchor: NSRect) {
        let scrRect = screenRect(for: anchor)
        let era = EraManager.shared.activeEra

        if TrayFlyoutWindow.shared.isVisible && TrayFlyoutWindow.shared.currentTrayControl == control {
            TrayFlyoutWindow.shared.hideFlyout()
            activeTrayControl = nil
            needsDisplay = true
            return
        }

        activeTrayControl = control
        needsDisplay = true

        let flyoutView: NSView
        switch control {
        case .volume:
            flyoutView = VolumeFlyoutFactory.makeFlyout(for: era)
        case .clock:
            flyoutView = ClockFlyoutFactory.makeFlyout(for: era)
        case .network:
            flyoutView = NetworkFlyoutFactory.makeFlyout(for: era)
        case .battery:
            if era.behaviors.unifiedSystemTrayCluster {
                flyoutView = QuickSettingsFlyoutView()
            } else {
                flyoutView = BatteryFlyoutFactory.makeFlyout(for: era)
            }
        case .quickSettings:
            flyoutView = QuickSettingsFlyoutView()
        case .actionCenter:
            flyoutView = NetworkFlyoutFactory.makeFlyout(for: era)
        }

        TrayFlyoutWindow.shared.showAbove(anchorRect: scrRect, view: flyoutView, control: control) { [weak self] in
            self?.activeTrayControl = nil
            self?.needsDisplay = true
        }
    }

    // MARK: - Tracking Areas & Mouse Hover
    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea {
            removeTrackingArea(ta)
        }
        let ta = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(ta)
        trackingArea = ta
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        var newHovered: TrayControl? = nil

        let era = EraManager.shared.activeEra
        if era.behaviors.unifiedSystemTrayCluster && quickSettingsRect.width > 0 && quickSettingsRect.contains(loc) {
            newHovered = .quickSettings
        } else if volumeIconRect.width > 0 && volumeIconRect.contains(loc) {
            newHovered = .volume
        } else if networkIconRect.width > 0 && networkIconRect.contains(loc) {
            newHovered = .network
        } else if batteryIconRect.width > 0 && batteryIconRect.contains(loc) {
            newHovered = .battery
        } else if clockRect.width > 0 && clockRect.contains(loc) {
            newHovered = .clock
        } else if actionCenterRect.width > 0 && actionCenterRect.contains(loc) {
            newHovered = .actionCenter
        }

        if newHovered != hoveredTrayControl {
            hoveredTrayControl = newHovered
            needsDisplay = true
        }
    }

    override public func mouseExited(with event: NSEvent) {
        if hoveredTrayControl != nil {
            hoveredTrayControl = nil
            needsDisplay = true
        }
    }


    /// Returns the layout rectangle for a given task item.
    public func rect(for item: TaskItem) -> NSRect? {
        return taskButtonRects.first(where: { $0.0.pid == item.pid })?.1
    }
}

extension TaskbarView: NSMenuItemValidation {
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
}
