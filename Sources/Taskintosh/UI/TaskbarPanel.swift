import TaskintoshKit
import AppKit


public final class TaskbarPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isOpaque = true
        self.hasShadow = false
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
    }

    override public var canBecomeKey: Bool {
        return false
    }

    override public var canBecomeMain: Bool {
        return false
    }

    /// Updates the panel's geometry to match the active era and screen configuration.
    public func updateGeometry(era: EraPackage, screen: NSScreen, preset: TaskbarSizePreset? = nil, animated: Bool = false, duration: TimeInterval = 0.38) {
        let sizePreset: TaskbarSizePreset
        if let p = preset {
            sizePreset = p
        } else if let raw = UserDefaults.standard.string(forKey: "TaskbarSizePreset"),
                  let p = TaskbarSizePreset(rawValue: raw) {
            sizePreset = p
        } else {
            sizePreset = .normal
        }

        let height = era.layout.taskbarHeight(for: sizePreset)
        let targetFrame = DisplayManager.shared.frame(
            for: era.layout.defaultEdge,
            height: height,
            on: screen
        )

        if animated && self.frame != targetFrame {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().setFrame(targetFrame, display: true)
            }, completionHandler: {
                AppDelegate.shared?.updateTaskbarWindowLayout(frame: targetFrame, isVisible: true)
            })
        } else {
            self.setFrame(targetFrame, display: true, animate: false)
            AppDelegate.shared?.updateTaskbarWindowLayout(frame: targetFrame, isVisible: true)
        }
    }
}
