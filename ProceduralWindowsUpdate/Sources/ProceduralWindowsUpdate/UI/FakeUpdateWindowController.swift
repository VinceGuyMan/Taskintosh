import AppKit
import SwiftUI

/// Custom AppKit Window subclass that intercepts Escape via AppKit's native responder chain (`cancelOperation:`).
private final class FakeUpdateAppKitWindow: NSWindow {
    var onEscapePressed: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onEscapePressed?()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 { // ESC
            onEscapePressed?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func standardWindowButton(_ b: NSWindow.ButtonType) -> NSButton? {
        let btn = super.standardWindowButton(b)
        btn?.isHidden = true
        return btn
    }
}

/// AppKit Window Controller for presenting the Fake Windows Update window.
/// Handles Esc key interception at the AppKit window level, window centering, and cleanup.
/// In clean presentation mode, suppresses macOS title bar and traffic-light controls,
/// and tightly sizes the AppKit window to the active era renderer without any simulated desktop background.
@MainActor
public final class FakeUpdateWindowController: NSWindowController, NSWindowDelegate {

    public let controller: FakeUpdateController
    public let cleanPresentationMode: Bool
    private var localMonitor: Any?
    private var closeOnceAction: OnceAction?

    private func makeCloseOnceAction() -> OnceAction {
        OnceAction { [weak self] in
            self?.close()
        }
    }

    public init(controller: FakeUpdateController, cleanPresentationMode: Bool = true) {
        self.controller = controller
        self.cleanPresentationMode = cleanPresentationMode

        let targetSize = controller.activeEra.windowSize
        let styleMask: NSWindow.StyleMask = cleanPresentationMode
            ? [.borderless]
            : [.titled, .closable, .miniaturizable]

        let window = FakeUpdateAppKitWindow(
            contentRect: NSRect(origin: .zero, size: targetSize),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = "Windows Update"
        window.isReleasedWhenClosed = false

        if cleanPresentationMode {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.isMovableByWindowBackground = true

            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }

        super.init(window: window)
        window.delegate = self

        // Guaranteed exactly-once close action for this presentation.
        self.closeOnceAction = makeCloseOnceAction()

        // Connect native AppKit Escape interception
        window.onEscapePressed = { [weak self] in
            guard let self = self else { return }
            self.controller.cancel()
            self.closeOnceAction?()
        }

        let hostingView = NSHostingView(
            rootView: FakeUpdateWindowView(controller: controller, onClose: { [weak self] in
                self?.closeOnceAction?()
            })
        )
        window.contentView = hostingView

        // Tightly size after setting contentView
        if cleanPresentationMode {
            window.setFrame(NSRect(origin: window.frame.origin, size: targetSize), display: true)
        } else {
            window.setContentSize(targetSize)
        }
        window.center()

        // Secondary global local monitor for Escape key (keycode 53)
        self.localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.controller.cancel()
                self?.closeOnceAction?()
                return nil
            }
            return event
        }
    }

    public convenience init() {
        self.init(controller: FakeUpdateController(), cleanPresentationMode: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    public func windowWillClose(_ notification: Notification) {
        if controller.state.status.isActive {
            controller.cancel()
        }
        if FakeUpdateSystem.activeWindowController === self {
            FakeUpdateSystem.activeWindowController = nil
        }
    }

    /// Shows the simulated update window tightly sized to the active era and launches the procedural simulation.
    public func present(
        era: WindowsEra,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .authentic,
        seed: UInt64? = nil
    ) {
        guard let window = self.window else { return }

        // OnceAction is intentionally one-shot. Re-arm it whenever this
        // controller is reused by FakeUpdateSystem for a later update.
        closeOnceAction = makeCloseOnceAction()

        // Tightly size window to the specific era renderer
        let targetSize = era.windowSize
        if cleanPresentationMode {
            window.setFrame(NSRect(origin: window.frame.origin, size: targetSize), display: true)
        } else {
            window.setContentSize(targetSize)
        }
        window.center()

        if cleanPresentationMode {
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        controller.start(era: era, duration: duration, personality: personality, seed: seed)
    }
}
