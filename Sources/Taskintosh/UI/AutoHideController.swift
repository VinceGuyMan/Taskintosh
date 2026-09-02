import AppKit
import TaskintoshKit

public final class AutoHideController {
    public private(set) var isEnabled: Bool = false
    public private(set) var isHidden: Bool = false

    private weak var panel: TaskbarPanel?
    private var globalEventMonitor: Any?
    private var hideTimer: Timer?

    public init(panel: TaskbarPanel) {
        self.panel = panel
        setupMouseMonitoring()
    }

    deinit {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hideTimer?.invalidate()
    }

    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        if !enabled && isHidden {
            revealPanel(animated: true)
        }
    }

    public func toggle() {
        setEnabled(!isEnabled)
    }

    private func setupMouseMonitoring() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(screenLocation: NSEvent.mouseLocation)
        }
    }

    public func handleMouseMoved(screenLocation: NSPoint) {
        guard isEnabled, let panel = panel, let screen = panel.screen else { return }

        // Do not auto-hide if Start menu is open
        if StartMenuWindow.shared.isVisible {
            hideTimer?.invalidate()
            hideTimer = nil
            if isHidden {
                revealPanel(animated: true)
            }
            return
        }

        let panelFrame = panel.frame
        let isInsidePanel = panelFrame.contains(screenLocation)

        if isInsidePanel {
            hideTimer?.invalidate()
            hideTimer = nil
            if isHidden {
                revealPanel(animated: true)
            }
        } else {
            // Check if mouse is at the bottom trigger edge
            let triggerHeight: CGFloat = 3.0
            let edgeTriggerRect = NSRect(
                x: screen.frame.minX,
                y: screen.frame.minY,
                width: screen.frame.width,
                height: triggerHeight
            )

            if edgeTriggerRect.contains(screenLocation) {
                hideTimer?.invalidate()
                hideTimer = nil
                revealPanel(animated: true)
            } else if !isHidden && hideTimer == nil {
                // Start countdown to hide
                let delay = EraManager.shared.activeEra.behaviors.autoHideDelaySeconds
                hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.hidePanel(animated: true)
                }
            }
        }
    }

    public func hidePanel(animated: Bool) {
        guard let panel = panel, let screen = panel.screen, isEnabled, !isHidden else { return }
        hideTimer?.invalidate()
        hideTimer = nil

        let era = EraManager.shared.activeEra
        let peek = era.behaviors.autoHidePeekMargin
        let height = era.layout.taskbarHeight

        let hiddenFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY - height + peek,
            width: screen.frame.width,
            height: height
        )

        isHidden = true
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                panel.animator().setFrame(hiddenFrame, display: true)
            }
        } else {
            panel.setFrame(hiddenFrame, display: true)
        }
    }

    public func revealPanel(animated: Bool) {
        guard let panel = panel, let screen = panel.screen, isHidden else { return }
        hideTimer?.invalidate()
        hideTimer = nil

        let era = EraManager.shared.activeEra
        let height = era.layout.taskbarHeight

        let visibleFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: height
        )

        isHidden = false
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                panel.animator().setFrame(visibleFrame, display: true)
            }
        } else {
            panel.setFrame(visibleFrame, display: true)
        }
    }
}
