import AppKit
import TaskintoshKit

// MARK: - Factory for Era-Specific Volume Flyout
public enum VolumeFlyoutFactory {
    public static func makeFlyout(for era: EraPackage) -> NSView {
        switch era.theme.startMenuType {
        case .classicOneColumn:
            return Win95VolumeFlyoutView()
        case .twoColumnXP:
            return WinXPVolumeFlyoutView()
        case .twoColumnGlass:
            return Win7VolumeFlyoutView()
        case .tileLauncher, .modernTiles:
            return Win8VolumeFlyoutView()
        case .hybridMenu:
            return Win10VolumeFlyoutView()
        case .centeredFlyout:
            return Win11VolumeFlyoutView()
        default:
            return Win10VolumeFlyoutView()
        }
    }
}

// MARK: - Windows 95 Classic Volume Flyout
public final class Win95VolumeFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDragging = false
    private let trackY: CGFloat = 36
    private let trackHeight: CGFloat = 72
    private let trackX: CGFloat = 35

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 72, height: 136))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = (EraManager.shared.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }) ?? EraManager.shared.activeEra).theme
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let titleStr = NSAttributedString(string: "Volume", attributes: titleAttrs)
        titleStr.draw(at: NSPoint(x: round(bounds.midX - titleStr.size().width / 2.0), y: bounds.height - 18))

        // Sunken Track
        let trackRect = NSRect(x: trackX, y: trackY, width: 4, height: trackHeight)
        BevelRenderer.shared.drawSunkenBevel(in: trackRect, theme: theme)

        // Tick marks on left
        for i in 0...4 {
            let ty = trackY + CGFloat(i) * (trackHeight / 4.0)
            NSColor.darkGray.setFill()
            NSRect(x: trackX - 7, y: ty, width: 4, height: 1).fill()
        }

        // 3D Beveled Thumb
        let thumbY = trackY + CGFloat(volume) / 100.0 * trackHeight - 5
        let thumbRect = NSRect(x: trackX - 9, y: thumbY, width: 22, height: 10)
        theme.surfaceColor.setFill()
        thumbRect.fill()
        BevelRenderer.shared.drawRaisedBevel(in: thumbRect, theme: theme)

        // Mute Checkbox at bottom
        let checkRect = NSRect(x: 9, y: 10, width: 12, height: 12)
        NSColor.white.setFill()
        checkRect.fill()
        BevelRenderer.shared.drawSunkenBevel(in: checkRect, theme: theme)

        if isMuted {
            let checkAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor.black]
            NSAttributedString(string: "✓", attributes: checkAttrs).draw(at: NSPoint(x: 10, y: 9))
        }

        let muteAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.black]
        NSAttributedString(string: "Mute", attributes: muteAttrs).draw(at: NSPoint(x: 25, y: 9))
    }

    private func updateVolumeFromY(_ y: CGFloat) {
        let clampedY = max(trackY, min(trackY + trackHeight, y))
        let pct = Int(((clampedY - trackY) / trackHeight) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 26 {
            // Checkbox area
            isMuted.toggle()
            SystemMonitor.shared.setMuted(isMuted)
            needsDisplay = true
        } else {
            isDragging = true
            updateVolumeFromY(loc.y)
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromY(loc.y)
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}

// MARK: - Windows XP Luna Volume Flyout
public final class WinXPVolumeFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDragging = false
    private let trackY: CGFloat = 38
    private let trackHeight: CGFloat = 74
    private let trackX: CGFloat = 37

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 76, height: 144))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Outer surface & Bevel
        NSColor(srgbRed: 0.93, green: 0.93, blue: 0.95, alpha: 1.0).setFill()
        bounds.fill()
        NSColor(srgbRed: 0.08, green: 0.22, blue: 0.60, alpha: 1.0).setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        path.stroke()

        // Top Luna Header
        let headRect = NSRect(x: 1, y: bounds.height - 22, width: bounds.width - 2, height: 21)
        let grad = NSGradient(starting: NSColor(srgbRed: 0.14, green: 0.37, blue: 0.86, alpha: 1.0), ending: NSColor(srgbRed: 0.24, green: 0.55, blue: 0.95, alpha: 1.0))
        grad?.draw(in: headRect, angle: 90)

        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor.white]
        let titleStr = NSAttributedString(string: "Volume", attributes: titleAttrs)
        titleStr.draw(at: NSPoint(x: round(headRect.midX - titleStr.size().width / 2.0), y: headRect.midY - 6))

        // Track
        let trackRect = NSRect(x: trackX, y: trackY, width: 3, height: trackHeight)
        NSColor.darkGray.setFill()
        trackRect.fill()

        // Thumb (Luna blue circle)
        let thumbY = trackY + CGFloat(volume) / 100.0 * trackHeight - 7
        let thumbRect = NSRect(x: trackX - 6, y: thumbY, width: 15, height: 14)
        let thumbGrad = NSGradient(starting: NSColor(srgbRed: 0.18, green: 0.44, blue: 0.90, alpha: 1.0), ending: NSColor(srgbRed: 0.35, green: 0.65, blue: 1.0, alpha: 1.0))
        let thumbPath = NSBezierPath(roundedRect: thumbRect, xRadius: 3, yRadius: 3)
        thumbGrad?.draw(in: thumbPath, angle: 90)
        NSColor(srgbRed: 0.08, green: 0.22, blue: 0.60, alpha: 1.0).setStroke()
        thumbPath.stroke()

        // Mute Checkbox
        let checkRect = NSRect(x: 10, y: 11, width: 12, height: 12)
        NSColor.white.setFill()
        checkRect.fill()
        NSColor.gray.setStroke()
        NSBezierPath(rect: checkRect).stroke()

        if isMuted {
            let checkAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor(srgbRed: 0.1, green: 0.4, blue: 0.8, alpha: 1.0)]
            NSAttributedString(string: "✓", attributes: checkAttrs).draw(at: NSPoint(x: 11, y: 10))
        }

        let muteAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.black]
        NSAttributedString(string: "Mute", attributes: muteAttrs).draw(at: NSPoint(x: 26, y: 10))
    }

    private func updateVolumeFromY(_ y: CGFloat) {
        let clampedY = max(trackY, min(trackY + trackHeight, y))
        let pct = Int(((clampedY - trackY) / trackHeight) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 28 {
            isMuted.toggle()
            SystemMonitor.shared.setMuted(isMuted)
            needsDisplay = true
        } else {
            isDragging = true
            updateVolumeFromY(loc.y)
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromY(loc.y)
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}

// MARK: - Windows 7 Aero Glass Volume Flyout
public final class Win7VolumeFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDragging = false
    private let trackY: CGFloat = 52
    private let trackHeight: CGFloat = 70
    private let trackX: CGFloat = 32

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 68, height: 168))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Aero Glass Gradient
        let glassGrad = NSGradient(colors: [
            NSColor(srgbRed: 0.08, green: 0.12, blue: 0.18, alpha: 0.94),
            NSColor(srgbRed: 0.14, green: 0.20, blue: 0.28, alpha: 0.92)
        ])
        glassGrad?.draw(in: bounds, angle: 90)

        // Glass Border
        NSColor(white: 1.0, alpha: 0.25).setStroke()
        let bPath = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        bPath.lineWidth = 1
        bPath.stroke()

        // Device text
        let devAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.white]
        let devStr = NSAttributedString(string: "Speakers", attributes: devAttrs)
        devStr.draw(at: NSPoint(x: round(bounds.midX - devStr.size().width / 2.0), y: bounds.height - 20))

        // Percentage text
        let pctAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.white]
        let pctStr = NSAttributedString(string: "\(volume)", attributes: pctAttrs)
        pctStr.draw(at: NSPoint(x: round(bounds.midX - pctStr.size().width / 2.0), y: bounds.height - 35))

        // Track
        let trackRect = NSRect(x: trackX, y: trackY, width: 5, height: trackHeight)
        NSColor.black.withAlphaComponent(0.4).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: 2, yRadius: 2).fill()

        let filledH = trackHeight * CGFloat(volume) / 100.0
        let fillRect = NSRect(x: trackX, y: trackY, width: 5, height: filledH)
        NSColor(srgbRed: 0.20, green: 0.50, blue: 0.95, alpha: 0.85).setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: 2, yRadius: 2).fill()

        // Thumb (Aero Glass specular pill)
        let thumbY = trackY + filledH - 5
        let thumbRect = NSRect(x: trackX - 7, y: thumbY, width: 19, height: 10)
        NSColor(white: 1.0, alpha: 0.9).setFill()
        let tPath = NSBezierPath(roundedRect: thumbRect, xRadius: 3, yRadius: 3)
        tPath.fill()
        NSColor(srgbRed: 0.20, green: 0.50, blue: 0.95, alpha: 0.9).setStroke()
        tPath.stroke()

        // Speaker icon at bottom
        let spkRect = NSRect(x: bounds.midX - 8, y: 28, width: 16, height: 16)
        ProceduralIcons.shared.soundIcon(size: 16, color: .white, isMuted: isMuted).draw(in: spkRect)

        // Mixer Link
        let mixAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor(srgbRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)]
        let mixStr = NSAttributedString(string: "Mixer", attributes: mixAttrs)
        mixStr.draw(at: NSPoint(x: round(bounds.midX - mixStr.size().width / 2.0), y: 8))
    }

    private func updateVolumeFromY(_ y: CGFloat) {
        let clampedY = max(trackY, min(trackY + trackHeight, y))
        let pct = Int(((clampedY - trackY) / trackHeight) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 22 {
            // Click Mixer -> open macOS Sound settings
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        } else if loc.y < 46 {
            // Toggle Mute
            isMuted.toggle()
            SystemMonitor.shared.setMuted(isMuted)
            needsDisplay = true
        } else {
            isDragging = true
            updateVolumeFromY(loc.y)
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromY(loc.y)
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}

// MARK: - Windows 8.1 Modern Slate Volume Flyout
public final class Win8VolumeFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDragging = false
    private let trackY: CGFloat = 38
    private let trackHeight: CGFloat = 68
    private let trackX: CGFloat = 29

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 64, height: 144))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Flat Dark Slate
        NSColor(srgbRed: 0.08, green: 0.18, blue: 0.28, alpha: 0.96).setFill()
        bounds.fill()
        NSColor(white: 1.0, alpha: 0.15).setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()

        // Large bold percentage
        let pctAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 16), .foregroundColor: NSColor.white]
        let pctStr = NSAttributedString(string: "\(volume)", attributes: pctAttrs)
        pctStr.draw(at: NSPoint(x: round(bounds.midX - pctStr.size().width / 2.0), y: bounds.height - 28))

        // Flat Vertical Track
        let trackRect = NSRect(x: trackX, y: trackY, width: 6, height: trackHeight)
        NSColor.white.withAlphaComponent(0.2).setFill()
        trackRect.fill()

        let filledH = trackHeight * CGFloat(volume) / 100.0
        let fillRect = NSRect(x: trackX, y: trackY, width: 6, height: filledH)
        NSColor(srgbRed: 0.0, green: 0.65, blue: 0.95, alpha: 1.0).setFill()
        fillRect.fill()

        // Sharp Rectangular Thumb
        let thumbY = trackY + filledH - 4
        let thumbRect = NSRect(x: trackX - 7, y: thumbY, width: 20, height: 8)
        NSColor.white.setFill()
        thumbRect.fill()

        // Speaker icon at bottom
        let spkRect = NSRect(x: bounds.midX - 8, y: 12, width: 16, height: 16)
        ProceduralIcons.shared.soundIcon(size: 16, color: .white, isMuted: isMuted).draw(in: spkRect)
    }

    private func updateVolumeFromY(_ y: CGFloat) {
        let clampedY = max(trackY, min(trackY + trackHeight, y))
        let pct = Int(((clampedY - trackY) / trackHeight) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 30 {
            isMuted.toggle()
            SystemMonitor.shared.setMuted(isMuted)
            needsDisplay = true
        } else {
            isDragging = true
            updateVolumeFromY(loc.y)
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromY(loc.y)
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}

// MARK: - Windows 10 Acrylic Horizontal Volume Flyout
public final class Win10VolumeFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDragging = false
    private let trackX: CGFloat = 42
    private let trackWidth: CGFloat = 178
    private let trackY: CGFloat = 18

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 270, height: 64))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Dark Acrylic Background
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 0.96).setFill()
        bounds.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()

        // Device output text at top
        let devAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Speakers (Mac Audio Output)", attributes: devAttrs).draw(at: NSPoint(x: 14, y: bounds.height - 20))

        // Mute Button Icon on left
        let spkRect = NSRect(x: 14, y: trackY - 6, width: 20, height: 20)
        ProceduralIcons.shared.soundIcon(size: 18, color: .white, isMuted: isMuted).draw(in: spkRect)

        // Horizontal Track
        let trackRect = NSRect(x: trackX, y: trackY + 2, width: trackWidth, height: 4)
        NSColor.white.withAlphaComponent(0.25).setFill()
        trackRect.fill()

        let filledW = trackWidth * CGFloat(volume) / 100.0
        let fillRect = NSRect(x: trackX, y: trackY + 2, width: filledW, height: 4)
        NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0).setFill()
        fillRect.fill()

        // Thumb (circular dot)
        let thumbX = trackX + filledW - 6
        let thumbRect = NSRect(x: thumbX, y: trackY - 3, width: 14, height: 14)
        NSColor.white.setFill()
        NSBezierPath(ovalIn: thumbRect).fill()

        // Percentage text on right
        let pctAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 12), .foregroundColor: NSColor.white]
        let pctStr = NSAttributedString(string: "\(volume)", attributes: pctAttrs)
        pctStr.draw(at: NSPoint(x: bounds.width - 38, y: trackY - 4))
    }

    private func updateVolumeFromX(_ x: CGFloat) {
        let clampedX = max(trackX, min(trackX + trackWidth, x))
        let pct = Int(((clampedX - trackX) / trackWidth) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.x < 38 {
            isMuted.toggle()
            SystemMonitor.shared.setMuted(isMuted)
            needsDisplay = true
        } else {
            isDragging = true
            updateVolumeFromX(loc.x)
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromX(loc.x)
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}

// MARK: - Windows 11 Mica Volume & Quick Audio Flyout
public final class Win11VolumeFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDragging = false
    private let trackX: CGFloat = 46
    private let trackWidth: CGFloat = 176
    private let trackY: CGFloat = 18

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 270, height: 66))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Frosted Mica with 10px rounded corners
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.14, alpha: 0.96).setFill()
        path.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        path.stroke()

        // Device header
        let devAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Speakers (Mac Default Audio) ›", attributes: devAttrs).draw(at: NSPoint(x: 14, y: bounds.height - 20))

        // Mute button in rounded box
        let muteBox = NSRect(x: 14, y: trackY - 5, width: 24, height: 24)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: muteBox, xRadius: 5, yRadius: 5).fill()
        ProceduralIcons.shared.soundIcon(size: 15, color: .white, isMuted: isMuted).draw(in: NSRect(x: muteBox.midX - 7.5, y: muteBox.midY - 7.5, width: 15, height: 15))

        // Track with rounded pill
        let trackRect = NSRect(x: trackX, y: trackY + 2, width: trackWidth, height: 5)
        NSColor.white.withAlphaComponent(0.2).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: 2.5, yRadius: 2.5).fill()

        let filledW = trackWidth * CGFloat(volume) / 100.0
        let fillRect = NSRect(x: trackX, y: trackY + 2, width: filledW, height: 5)
        NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: 2.5, yRadius: 2.5).fill()

        // Thumb pill
        let thumbX = trackX + filledW - 4
        let thumbRect = NSRect(x: thumbX, y: trackY - 3, width: 8, height: 15)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: thumbRect, xRadius: 3, yRadius: 3).fill()

        // Percentage text
        let pctAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: NSColor.white]
        let pctStr = NSAttributedString(string: "\(volume)%", attributes: pctAttrs)
        pctStr.draw(at: NSPoint(x: bounds.width - 40, y: trackY - 4))
    }

    private func updateVolumeFromX(_ x: CGFloat) {
        let clampedX = max(trackX, min(trackX + trackWidth, x))
        let pct = Int(((clampedX - trackX) / trackWidth) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.x < 42 {
            isMuted.toggle()
            SystemMonitor.shared.setMuted(isMuted)
            needsDisplay = true
        } else {
            isDragging = true
            updateVolumeFromX(loc.x)
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromX(loc.x)
    }

    override public func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}
