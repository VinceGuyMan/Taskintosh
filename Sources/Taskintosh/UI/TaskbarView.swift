import AppKit
import Combine
import TaskintoshKit

public final class TaskbarView: NSView {
    private var cancellables = Set<AnyCancellable>()
    private var isStartButtonPressed: Bool = false
    private var taskButtonRects: [(TaskItem, NSRect)] = []
    private var startButtonRect: NSRect = .zero
    private var trayRect: NSRect = .zero
    private var volumeIconRect: NSRect = .zero
    private var eraIconRect: NSRect = .zero
    private var clockRect: NSRect = .zero

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
                self?.needsDisplay = true
            }
            .store(in: &cancellables)

        SystemMonitor.shared.$timeString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let era = EraManager.shared.activeEra
        let theme = era.theme
        let layout = era.layout

        // 1. Taskbar Background
        theme.backgroundColor.setFill()
        bounds.fill()

        // 2. Classic top 3D highlight line
        theme.lightHighlightColor.setFill()
        NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()

        // 3. Draw Start Button
        let btnH: CGFloat = bounds.height - 6
        let btnW = layout.startButtonWidth
        startButtonRect = NSRect(x: layout.paddingHorizontal + 2, y: 3, width: btnW, height: btnH)
        drawStartButton(in: startButtonRect, era: era)

        // 4. Draw System Tray on the right
        let trayW: CGFloat = 92
        trayRect = NSRect(x: bounds.width - trayW - 4, y: 3, width: trayW, height: btnH)
        drawSystemTray(in: trayRect, era: era)

        // 5. Draw Running Task Buttons
        let tasksStartX = startButtonRect.maxX + 6
        let tasksEndX = trayRect.minX - 4
        let availableWidth = max(0, tasksEndX - tasksStartX)

        let items = RunningAppWatcher.shared.taskItems
        taskButtonRects.removeAll()

        if !items.isEmpty && availableWidth > 20 {
            let totalSpacing = CGFloat(items.count - 1) * layout.itemSpacing
            let rawButtonWidth = (availableWidth - totalSpacing) / CGFloat(items.count)
            let buttonWidth = max(layout.taskButtonMinWidth, min(layout.taskButtonMaxWidth, rawButtonWidth))

            for (index, item) in items.enumerated() {
                let x = tasksStartX + CGFloat(index) * (buttonWidth + layout.itemSpacing)
                if x + buttonWidth > tasksEndX { break }

                let itemRect = NSRect(x: x, y: 3, width: buttonWidth, height: btnH)
                taskButtonRects.append((item, itemRect))
                drawTaskButton(item: item, in: itemRect, era: era)
            }
        }
    }

    private func drawStartButton(in rect: NSRect, era: EraPackage) {
        let theme = era.theme
        let isPressed = isStartButtonPressed || StartMenuWindow.shared.isVisible

        if isPressed {
            theme.surfaceColor.setFill()
            rect.fill()
            BevelRenderer.shared.drawSunkenBevel(in: rect, theme: theme)
        } else {
            theme.surfaceColor.setFill()
            rect.fill()
            BevelRenderer.shared.drawRaisedBevel(in: rect, theme: theme)
        }

        let offset: CGFloat = isPressed ? 1.0 : 0.0

        // Start Emblem Icon
        let emblem = era.image(named: "start_emblem") ?? ProceduralIcons.shared.startEmblem(size: 16)
        let emblemRect = NSRect(x: rect.minX + 4 + offset, y: rect.midY - 8 - offset, width: 16, height: 16)
        emblem.draw(in: emblemRect)

        // Start Label
        let font = theme.boldFont(size: 11)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor
        ]
        let str = NSAttributedString(string: theme.startButtonText, attributes: attrs)
        str.draw(at: NSPoint(x: rect.minX + 23 + offset, y: rect.midY - 7 - offset))
    }

    private func drawTaskButton(item: TaskItem, in rect: NSRect, era: EraPackage) {
        let theme = era.theme
        let isFront = item.isActive

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

        let offset: CGFloat = isFront ? 1.0 : 0.0

        // App Icon
        if let icon = item.icon {
            let iconRect = NSRect(x: rect.minX + 4 + offset, y: rect.midY - 8 - offset, width: 16, height: 16)
            icon.draw(in: iconRect)
        }

        // App Title
        let font = isFront ? theme.boldFont(size: 10) : theme.font(size: 10)
        let textColor = isFront ? theme.activeTextColor : theme.textColor
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: style
        ]

        let titleX = rect.minX + 24 + offset
        let titleW = max(0, rect.maxX - titleX - 4 - offset)
        let titleRect = NSRect(x: titleX, y: rect.midY - 7 - offset, width: titleW, height: 14)
        item.title.draw(in: titleRect, withAttributes: attrs)
    }

    private func drawSystemTray(in rect: NSRect, era: EraPackage) {
        let theme = era.theme

        // Sunken border
        theme.surfaceColor.setFill()
        rect.fill()
        BevelRenderer.shared.drawSunkenBevel(in: rect, theme: theme)

        // Volume Icon
        volumeIconRect = NSRect(x: rect.minX + 4, y: rect.midY - 7, width: 14, height: 14)
        let volImg = era.image(named: "sound") ?? ProceduralIcons.shared.soundIcon(size: 14)
        volImg.draw(in: volumeIconRect)

        // Era Switcher Icon
        eraIconRect = NSRect(x: rect.minX + 22, y: rect.midY - 7, width: 14, height: 14)
        let eraImg = ProceduralIcons.shared.taskintoshIcon(size: 14)
        eraImg.draw(in: eraIconRect)

        // Live Clock
        let timeStr = SystemMonitor.shared.timeString.isEmpty ? "12:00 PM" : SystemMonitor.shared.timeString
        let font = theme.font(size: 10)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor
        ]
        let str = NSAttributedString(string: timeStr, attributes: attrs)
        let strSize = str.size()
        clockRect = NSRect(x: rect.maxX - strSize.width - 6, y: rect.midY - strSize.height / 2.0, width: strSize.width, height: strSize.height)
        str.draw(at: clockRect.origin)
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        // 1. Start Button Click
        if startButtonRect.contains(loc) {
            isStartButtonPressed = true
            needsDisplay = true
            toggleStartMenu()
            return
        }

        // 2. Task Button Click
        for (item, rect) in taskButtonRects {
            if rect.contains(loc) {
                let era = EraManager.shared.activeEra
                RunningAppWatcher.shared.handleTaskItemClick(item, behavior: era.behaviors.clickActiveAppAction)
                return
            }
        }

        // 3. Tray item clicks
        if volumeIconRect.contains(loc) {
            openVolumePopover(at: loc)
            return
        }

        if eraIconRect.contains(loc) {
            AppDelegate.shared?.openEraManager()
            return
        }

        if clockRect.contains(loc) {
            openDatePopover(at: loc)
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
        let loc = convert(event.locationInWindow, from: nil)

        // Check if right-clicking a task button
        for (item, rect) in taskButtonRects {
            if rect.contains(loc) {
                showTaskContextMenu(for: item, at: loc)
                return
            }
        }

        // Otherwise, show taskbar context menu
        showTaskbarContextMenu(at: loc)
    }

    private func toggleStartMenu() {
        if StartMenuWindow.shared.isVisible {
            StartMenuWindow.shared.hideMenu()
        } else {
            let winOrigin = window?.frame.origin ?? .zero
            let menuRect = NSRect(x: winOrigin.x + startButtonRect.minX, y: winOrigin.y + bounds.height, width: startButtonRect.width, height: startButtonRect.height)
            StartMenuWindow.shared.showAbove(rect: menuRect)
        }
        needsDisplay = true
    }

    private func showTaskContextMenu(for item: TaskItem, at location: NSPoint) {
        let menu = NSMenu(title: item.title)

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

        menu.popUp(positioning: nil, at: location, in: self)
    }

    @objc private func taskActionRestore(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        item.runningApp?.unhide()
        item.runningApp?.activate(options: [.activateIgnoringOtherApps])
    }

    @objc private func taskActionMinimize(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        item.runningApp?.hide()
    }

    @objc private func taskActionClose(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? TaskItem else { return }
        item.runningApp?.terminate()
    }

    private func showTaskbarContextMenu(at location: NSPoint) {
        let autoHide = AppDelegate.shared?.isAutoHideEnabled ?? false
        let menu = TaskbarContextMenu(autoHideEnabled: autoHide) { [weak self] in
            self?.needsDisplay = true
        }
        menu.popUp(positioning: nil, at: location, in: self)
    }

    private func openDatePopover(at location: NSPoint) {
        let alert = NSAlert()
        alert.messageText = "Date & Time"
        alert.informativeText = SystemMonitor.shared.dateString
        alert.runModal()
    }

    private func openVolumePopover(at location: NSPoint) {
        let currentVol = SystemMonitor.shared.volumeLevel
        let alert = NSAlert()
        alert.messageText = "Audio Volume"
        alert.informativeText = "Current macOS Volume: \(currentVol)%"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
