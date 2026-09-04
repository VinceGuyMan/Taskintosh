import AppKit
import TaskintoshKit

public enum TrayControl: String, CaseIterable, Equatable {
    case volume
    case clock
    case network
    case battery
    case quickSettings // Win11 grouped pill
    case actionCenter
}

public final class TrayFlyoutWindow: NSWindow {
    public static let shared = TrayFlyoutWindow()

    public private(set) var currentTrayControl: TrayControl?
    public private(set) var lastDismissalTimestamp: TimeInterval = 0

    private var outsideClickMonitor: Any?
    private var localClickMonitor: Any?
    private var onDismissCallback: (() -> Void)?
    private var lastAnchorScreenRect: NSRect = .zero

    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 260),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .popUpMenu
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
    }

    override public var canBecomeKey: Bool {
        return true
    }

    public func showAbove(anchorRect: NSRect, view: NSView, control: TrayControl, onDismiss: (() -> Void)? = nil) {
        // If already open with the same control, toggle closed
        if isVisible && currentTrayControl == control {
            hideFlyout()
            return
        }

        // Mutual exclusivity with Start Menu
        if StartMenuWindow.shared.isVisible {
            StartMenuWindow.shared.hideMenu()
        }

        self.currentTrayControl = control
        self.onDismissCallback = onDismiss
        self.lastAnchorScreenRect = anchorRect

        self.contentView = view
        let contentSize = view.frame.size
        let era = EraManager.shared.activeEra
        let screen = DisplayManager.shared.currentScreen

        var x = anchorRect.midX - contentSize.width / 2.0
        var y = anchorRect.maxY + 2

        if era.layout.defaultEdge == .top {
            y = anchorRect.minY - contentSize.height - 2
        } else if y + contentSize.height > screen.visibleFrame.maxY - 6 {
            y = anchorRect.minY - contentSize.height - 2
        }

        // Keep strictly on screen horizontally and vertically
        x = max(screen.visibleFrame.minX + 6, min(screen.visibleFrame.maxX - contentSize.width - 6, x))
        y = max(screen.visibleFrame.minY + 6, min(screen.visibleFrame.maxY - contentSize.height - 6, y))

        self.setFrame(NSRect(x: x, y: y, width: contentSize.width, height: contentSize.height), display: true)
        self.makeKeyAndOrderFront(nil)

        setupClickMonitors()
    }

    public func hideFlyout() {
        guard isVisible || currentTrayControl != nil else { return }
        removeClickMonitors()
        self.orderOut(nil)
        self.currentTrayControl = nil
        self.lastDismissalTimestamp = Date().timeIntervalSinceReferenceDate
        self.contentView = nil
        let cb = onDismissCallback
        onDismissCallback = nil
        cb?()
    }

    private func setupClickMonitors() {
        removeClickMonitors()

        // Global click monitor for outside app clicks
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hideFlyout()
        }

        // Local click monitor for clicks in this app
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }

            let clickScreenLoc: NSPoint
            if let evWindow = event.window {
                clickScreenLoc = evWindow.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin
            } else {
                clickScreenLoc = NSEvent.mouseLocation
            }

            // If clicked on the anchor button that opened this flyout, toggle it closed & consume event
            if self.lastAnchorScreenRect.contains(clickScreenLoc) {
                self.hideFlyout()
                return nil
            }

            // If clicked outside flyout frame, dismiss
            if !self.frame.contains(clickScreenLoc) {
                self.hideFlyout()
            }
            return event
        }
    }

    private func removeClickMonitors() {
        if let m = outsideClickMonitor {
            NSEvent.removeMonitor(m)
            outsideClickMonitor = nil
        }
        if let m = localClickMonitor {
            NSEvent.removeMonitor(m)
            localClickMonitor = nil
        }
    }

    override public func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            hideFlyout()
            return
        }
        super.keyDown(with: event)
    }
}
