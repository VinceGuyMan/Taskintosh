import AppKit
import TaskintoshKit

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
    public func updateGeometry(era: EraPackage, screen: NSScreen) {
        let targetFrame = DisplayManager.shared.frame(
            for: era.layout.defaultEdge,
            height: era.layout.taskbarHeight,
            on: screen
        )
        self.setFrame(targetFrame, display: true, animate: false)
    }
}
