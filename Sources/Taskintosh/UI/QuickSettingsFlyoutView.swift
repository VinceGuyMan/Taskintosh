import AppKit
import TaskintoshKit

public final class QuickSettingsFlyoutView: NSView {
    private var volume: Int = SystemMonitor.shared.volumeLevel
    private var isMuted: Bool = SystemMonitor.shared.isMuted
    private var isDraggingVolume = false
    private let volTrackX: CGFloat = 58
    private let volTrackWidth: CGFloat = 220
    private let volTrackY: CGFloat = 46

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 340, height: 210))
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Frosted Mica container
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.14, alpha: 0.96).setFill()
        path.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        path.stroke()

        // Quick action tiles (Wi-Fi, Bluetooth, Night Shift)
        let tileW: CGFloat = 96
        let tileH: CGFloat = 52
        let tileY: CGFloat = bounds.height - 72

        // Tile 1: Wi-Fi
        let wifiRect = NSRect(x: 16, y: tileY, width: tileW, height: tileH)
        let isConnected = SystemMonitor.shared.isNetworkConnected
        (isConnected ? NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0) : NSColor.white.withAlphaComponent(0.08)).setFill()
        NSBezierPath(roundedRect: wifiRect, xRadius: 8, yRadius: 8).fill()
        ProceduralIcons.shared.networkIcon(size: 20, color: .white, isConnected: isConnected, isWiFi: true).draw(in: NSRect(x: wifiRect.minX + 8, y: wifiRect.maxY - 28, width: 20, height: 20))
        let wifiAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Wi-Fi", attributes: wifiAttrs).draw(at: NSPoint(x: wifiRect.minX + 8, y: wifiRect.minY + 6))

        // Tile 2: Bluetooth
        let btRect = NSRect(x: 16 + tileW + 10, y: tileY, width: tileW, height: tileH)
        NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: btRect, xRadius: 8, yRadius: 8).fill()
        let btAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Bluetooth", attributes: btAttrs).draw(at: NSPoint(x: btRect.minX + 8, y: btRect.minY + 6))
        NSAttributedString(string: "ᛒ", attributes: [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: NSColor.white]).draw(at: NSPoint(x: btRect.minX + 10, y: btRect.maxY - 26))

        // Tile 3: Airplane / Network
        let airRect = NSRect(x: 16 + (tileW + 10) * 2, y: tileY, width: tileW, height: tileH)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: airRect, xRadius: 8, yRadius: 8).fill()
        NSAttributedString(string: "✈", attributes: [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: NSColor.white]).draw(at: NSPoint(x: airRect.minX + 10, y: airRect.maxY - 26))
        NSAttributedString(string: "Airplane", attributes: [.font: NSFont.systemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.white]).draw(at: NSPoint(x: airRect.minX + 8, y: airRect.minY + 6))

        // Volume row
        let muteBox = NSRect(x: 16, y: volTrackY - 6, width: 28, height: 28)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: muteBox, xRadius: 6, yRadius: 6).fill()
        ProceduralIcons.shared.soundIcon(size: 16, color: .white, isMuted: isMuted).draw(in: NSRect(x: muteBox.midX - 8, y: muteBox.midY - 8, width: 16, height: 16))

        // Slider track
        let trackRect = NSRect(x: volTrackX, y: volTrackY + 2, width: volTrackWidth, height: 6)
        NSColor.white.withAlphaComponent(0.2).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: 3, yRadius: 3).fill()

        let filledW = volTrackWidth * CGFloat(volume) / 100.0
        let fillRect = NSRect(x: volTrackX, y: volTrackY + 2, width: filledW, height: 6)
        NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: 3, yRadius: 3).fill()

        let thumbX = volTrackX + filledW - 4
        let thumbRect = NSRect(x: thumbX, y: volTrackY - 4, width: 8, height: 18)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: thumbRect, xRadius: 4, yRadius: 4).fill()

        let pctAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: NSColor.white]
        let pctStr = NSAttributedString(string: "\(volume)%", attributes: pctAttrs)
        pctStr.draw(at: NSPoint(x: bounds.width - 48, y: volTrackY))

        // Bottom footer: Battery status + Settings icon
        let dividerY: CGFloat = 34
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSRect(x: 16, y: dividerY, width: bounds.width - 32, height: 1).fill()

        if SystemMonitor.shared.hasBattery {
            let battRect = NSRect(x: 16, y: 10, width: 18, height: 18)
            ProceduralIcons.shared.batteryIcon(size: 18, color: .white, percentage: SystemMonitor.shared.batteryPercentage, isCharging: SystemMonitor.shared.isCharging).draw(in: battRect)
            let battAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.white]
            let battStr = "\(SystemMonitor.shared.batteryPercentage)%" + (SystemMonitor.shared.isCharging ? " (Charging)" : "")
            NSAttributedString(string: battStr, attributes: battAttrs).draw(at: NSPoint(x: 40, y: 10))
        }

        // Settings gear button at bottom right
        let gearAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.lightGray]
        NSAttributedString(string: "⚙", attributes: gearAttrs).draw(at: NSPoint(x: bounds.width - 32, y: 8))
    }

    private func updateVolumeFromX(_ x: CGFloat) {
        let clampedX = max(volTrackX, min(volTrackX + volTrackWidth, x))
        let pct = Int(((clampedX - volTrackX) / volTrackWidth) * 100.0)
        self.volume = max(0, min(100, pct))
        SystemMonitor.shared.setVolume(self.volume)
        needsDisplay = true
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 34 && loc.x > bounds.width - 40 {
            // Click settings gear -> open System Settings
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        } else if loc.y >= volTrackY - 10 && loc.y <= volTrackY + 20 {
            if loc.x < 48 {
                isMuted.toggle()
                SystemMonitor.shared.setMuted(isMuted)
                needsDisplay = true
            } else {
                isDraggingVolume = true
                updateVolumeFromX(loc.x)
            }
        } else if loc.y >= bounds.height - 72 {
            // Click Wi-Fi tile -> open Network Settings
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        }
    }

    override public func mouseDragged(with event: NSEvent) {
        guard isDraggingVolume else { return }
        let loc = convert(event.locationInWindow, from: nil)
        updateVolumeFromX(loc.x)
    }

    override public func mouseUp(with event: NSEvent) {
        isDraggingVolume = false
    }
}
