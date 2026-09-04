import AppKit
import TaskintoshKit

// MARK: - Factory for Era-Specific Battery Flyout
public enum BatteryFlyoutFactory {
    public static func makeFlyout(for era: EraPackage) -> NSView {
        switch era.theme.startMenuType {
        case .classicOneColumn:
            return Win95BatteryFlyoutView()
        case .twoColumnXP:
            return WinXPBatteryFlyoutView()
        case .twoColumnGlass:
            return Win7BatteryFlyoutView()
        case .tileLauncher, .modernTiles, .hybridMenu:
            return Win10BatteryFlyoutView()
        case .centeredFlyout:
            return Win10BatteryFlyoutView()
        default:
            return Win10BatteryFlyoutView()
        }
    }
}

// MARK: - Windows 10 Authentic Battery / Power Flyout
public final class Win10BatteryFlyoutView: NSView {
    private var powerMode: Int = 1 // 0: Best battery life, 1: Balanced, 2: Best performance
    private let sliderTrackX: CGFloat = 20
    private let sliderTrackWidth: CGFloat = 250
    private let sliderY: CGFloat = 66
    private var openSettingsRect: NSRect = .zero

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 290, height: 180))
        SystemMonitor.shared.updateBattery()
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 1. Dark Acrylic Background
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 0.96).setFill()
        bounds.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()

        let monitor = SystemMonitor.shared
        let pct = monitor.batteryPercentage
        let isCharging = monitor.isCharging
        let isAC = monitor.isConnectedToAC

        // 2. Battery Icon & Large Percentage Text
        let iconRect = NSRect(x: 20, y: bounds.height - 48, width: 24, height: 20)
        ProceduralIcons.shared.batteryIcon(size: 20, color: .white, percentage: pct, isCharging: isCharging).draw(in: iconRect)

        let pctAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .light),
            .foregroundColor: NSColor.white
        ]
        let pctStr = NSAttributedString(string: "\(pct)%", attributes: pctAttrs)
        pctStr.draw(at: NSPoint(x: 52, y: bounds.height - 50))

        // State & Estimated Time
        let stateText: String
        if isCharging {
            stateText = "Plugged in, charging"
        } else if isAC && monitor.isBatteryFullyCharged {
            stateText = "Fully charged (100%)"
        } else if let estimate = monitor.batteryTimeRemainingString {
            stateText = "\(estimate) (\(pct)% available)"
        } else {
            stateText = "\(pct)% remaining • Drawing from \(monitor.powerSourceString)"
        }

        let stateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.lightGray
        ]
        NSAttributedString(string: stateText, attributes: stateAttrs).draw(at: NSPoint(x: 20, y: bounds.height - 72))

        // 3. Power Mode Slider Section
        let modeNames = ["Best battery life", "Better battery (Balanced)", "Best performance"]
        let curModeName = modeNames[max(0, min(2, powerMode))]
        let modeLabelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: "Power mode: \(curModeName)", attributes: modeLabelAttrs).draw(at: NSPoint(x: 20, y: sliderY + 24))

        // Slider track
        let trackRect = NSRect(x: sliderTrackX, y: sliderY + 6, width: sliderTrackWidth, height: 4)
        NSColor.white.withAlphaComponent(0.25).setFill()
        trackRect.fill()

        // Tick marks at 0, 50%, 100%
        for i in 0...2 {
            let tx = sliderTrackX + CGFloat(i) * (sliderTrackWidth / 2.0)
            NSColor.white.withAlphaComponent(0.5).setFill()
            NSRect(x: tx - 1, y: sliderY + 2, width: 2, height: 12).fill()
        }

        // Thumb
        let thumbX = sliderTrackX + CGFloat(powerMode) * (sliderTrackWidth / 2.0)
        let thumbRect = NSRect(x: thumbX - 6, y: sliderY + 1, width: 12, height: 14)
        NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: thumbRect, xRadius: 2, yRadius: 2).fill()

        // Slider tick labels
        let subAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.lightGray]
        NSAttributedString(string: "Battery saver", attributes: subAttrs).draw(at: NSPoint(x: sliderTrackX, y: sliderY - 14))
        let perfStr = NSAttributedString(string: "Best performance", attributes: subAttrs)
        perfStr.draw(at: NSPoint(x: sliderTrackX + sliderTrackWidth - perfStr.size().width, y: sliderY - 14))

        // 4. Bottom Divider and Link
        let divY: CGFloat = 38
        NSColor.white.withAlphaComponent(0.12).setFill()
        NSRect(x: 16, y: divY, width: bounds.width - 32, height: 1).fill()

        openSettingsRect = NSRect(x: 16, y: 10, width: bounds.width - 32, height: 22)
        let linkAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor(srgbRed: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
        ]
        NSAttributedString(string: "Battery settings", attributes: linkAttrs).draw(at: NSPoint(x: openSettingsRect.minX + 2, y: openSettingsRect.minY + 3))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        // 1. Slider interaction
        if loc.y >= sliderY - 8 && loc.y <= sliderY + 22 {
            let normX = (loc.x - sliderTrackX) / sliderTrackWidth
            if normX < 0.33 {
                powerMode = 0
            } else if normX < 0.67 {
                powerMode = 1
            } else {
                powerMode = 2
            }
            needsDisplay = true
            return
        }

        // 2. Settings link
        if loc.y < 38 {
            TrayFlyoutWindow.shared.hideFlyout()
            openMacOSBatterySettings()
        }
    }

    private func openMacOSBatterySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else {
            MacOSLocationsService.shared.openSystemSettings()
        }
    }
}

// MARK: - Windows 7 Aero Glass Battery Flyout
public final class Win7BatteryFlyoutView: NSView {
    private var selectedPlan: Int = 0 // 0: Balanced, 1: Power saver

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 284, height: 170))
        SystemMonitor.shared.updateBattery()
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Aero Glass Gradient
        let glassGrad = NSGradient(colors: [
            NSColor(srgbRed: 0.08, green: 0.12, blue: 0.18, alpha: 0.96),
            NSColor(srgbRed: 0.14, green: 0.20, blue: 0.28, alpha: 0.94)
        ])
        glassGrad?.draw(in: bounds, angle: 90)
        NSColor(white: 1.0, alpha: 0.25).setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()

        let monitor = SystemMonitor.shared
        let pct = monitor.batteryPercentage
        let isCharging = monitor.isCharging

        // Battery Icon
        let iconRect = NSRect(x: 16, y: bounds.height - 44, width: 22, height: 22)
        ProceduralIcons.shared.batteryIcon(size: 20, color: .white, percentage: pct, isCharging: isCharging).draw(in: iconRect)

        // Percentage Title
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 12), .foregroundColor: NSColor.white]
        let statusTitle = isCharging ? "\(pct)% available (plugged in, charging)" : "\(pct)% remaining"
        NSAttributedString(string: statusTitle, attributes: titleAttrs).draw(at: NSPoint(x: 44, y: bounds.height - 34))

        let subAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.lightGray]
        let subTitle = monitor.isConnectedToAC ? "Power source: Power Adapter" : "Power source: Battery"
        NSAttributedString(string: subTitle, attributes: subAttrs).draw(at: NSPoint(x: 44, y: bounds.height - 48))

        // Power plan selector
        let planAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Select a power plan:", attributes: planAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 76))

        let optAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.white]

        // Radio 1: Balanced
        drawRadioButton(at: NSPoint(x: 18, y: bounds.height - 98), isSelected: selectedPlan == 0)
        NSAttributedString(string: "Balanced", attributes: optAttrs).draw(at: NSPoint(x: 36, y: bounds.height - 100))

        // Radio 2: Power saver
        drawRadioButton(at: NSPoint(x: 18, y: bounds.height - 120), isSelected: selectedPlan == 1)
        NSAttributedString(string: "Power saver", attributes: optAttrs).draw(at: NSPoint(x: 36, y: bounds.height - 122))

        // Bottom link
        let divY: CGFloat = 34
        NSColor(white: 1.0, alpha: 0.15).setFill()
        NSRect(x: 12, y: divY, width: bounds.width - 24, height: 1).fill()

        let linkAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor(srgbRed: 0.45, green: 0.78, blue: 1.0, alpha: 1.0)]
        NSAttributedString(string: "More power options", attributes: linkAttrs).draw(at: NSPoint(x: 16, y: 10))
    }

    private func drawRadioButton(at point: NSPoint, isSelected: Bool) {
        let circle = NSRect(x: point.x, y: point.y, width: 12, height: 12)
        NSColor.white.withAlphaComponent(0.2).setFill()
        NSBezierPath(ovalIn: circle).fill()
        NSColor.white.setStroke()
        NSBezierPath(ovalIn: circle).stroke()
        if isSelected {
            NSColor(srgbRed: 0.2, green: 0.7, blue: 1.0, alpha: 1.0).setFill()
            NSBezierPath(ovalIn: circle.insetBy(dx: 3, dy: 3)).fill()
        }
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y >= bounds.height - 104 && loc.y <= bounds.height - 92 {
            selectedPlan = 0
            needsDisplay = true
        } else if loc.y >= bounds.height - 126 && loc.y <= bounds.height - 114 {
            selectedPlan = 1
            needsDisplay = true
        } else if loc.y < 34 {
            TrayFlyoutWindow.shared.hideFlyout()
            if let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") {
                NSWorkspace.shared.open(url)
            } else {
                MacOSLocationsService.shared.openSystemSettings()
            }
        }
    }
}

// MARK: - Windows XP Luna Battery Flyout
public final class WinXPBatteryFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 170))
        SystemMonitor.shared.updateBattery()
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(srgbRed: 0.94, green: 0.94, blue: 0.96, alpha: 1.0).setFill()
        bounds.fill()
        NSColor(srgbRed: 0.08, green: 0.22, blue: 0.60, alpha: 1.0).setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        path.stroke()

        // Luna Header
        let headRect = NSRect(x: 1, y: bounds.height - 24, width: bounds.width - 2, height: 23)
        let grad = NSGradient(starting: NSColor(srgbRed: 0.14, green: 0.37, blue: 0.86, alpha: 1.0), ending: NSColor(srgbRed: 0.24, green: 0.55, blue: 0.95, alpha: 1.0))
        grad?.draw(in: headRect, angle: 90)
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Power Meter", attributes: titleAttrs).draw(at: NSPoint(x: 12, y: headRect.midY - 6))

        let monitor = SystemMonitor.shared
        let pct = monitor.batteryPercentage
        let isAC = monitor.isConnectedToAC

        let lblAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let valAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]

        NSAttributedString(string: "Power status:", attributes: lblAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 50))
        let pStatus = isAC ? (monitor.isCharging ? "Charging" : "AC Power / Online") : "On Battery"
        NSAttributedString(string: pStatus, attributes: valAttrs).draw(at: NSPoint(x: 110, y: bounds.height - 50))

        NSAttributedString(string: "Current source:", attributes: lblAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 68))
        NSAttributedString(string: monitor.powerSourceString, attributes: valAttrs).draw(at: NSPoint(x: 110, y: bounds.height - 68))

        NSAttributedString(string: "Remaining:", attributes: lblAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 86))
        NSAttributedString(string: "\(pct)%", attributes: valAttrs).draw(at: NSPoint(x: 110, y: bounds.height - 86))

        // Progress meter
        let meterRect = NSRect(x: 16, y: 44, width: bounds.width - 32, height: 16)
        NSColor.white.setFill()
        meterRect.fill()
        NSColor.darkGray.setStroke()
        NSBezierPath(rect: meterRect).stroke()

        let filledW = max(0, min(meterRect.width - 4, (meterRect.width - 4) * CGFloat(pct) / 100.0))
        NSColor(srgbRed: 0.2, green: 0.7, blue: 0.2, alpha: 1.0).setFill()
        NSRect(x: meterRect.minX + 2, y: meterRect.minY + 2, width: filledW, height: 12).fill()

        // Button
        let btnRect = NSRect(x: bounds.midX - 55, y: 10, width: 110, height: 24)
        let btnGrad = NSGradient(starting: NSColor(white: 0.95, alpha: 1.0), ending: NSColor(white: 0.85, alpha: 1.0))
        btnGrad?.draw(in: btnRect, angle: 90)
        NSColor.gray.setStroke()
        NSBezierPath(rect: btnRect).stroke()
        let bAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let bStr = NSAttributedString(string: "Power Options...", attributes: bAttrs)
        bStr.draw(at: NSPoint(x: round(btnRect.midX - bStr.size().width / 2.0), y: btnRect.midY - 7))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 36 {
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        }
    }
}

// MARK: - Windows 95 Classic Battery Flyout
public final class Win95BatteryFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 150))
        SystemMonitor.shared.updateBattery()
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = (EraManager.shared.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }) ?? EraManager.shared.activeEra).theme
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        NSAttributedString(string: "Battery Status", attributes: titleAttrs).draw(at: NSPoint(x: 12, y: bounds.height - 20))

        let monitor = SystemMonitor.shared
        let pct = monitor.batteryPercentage

        let tAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        NSAttributedString(string: "Power Source: \(monitor.powerSourceString)", attributes: tAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 48))
        NSAttributedString(string: "Battery Remaining: \(pct)%", attributes: tAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 66))

        // Sunken meter
        let meterRect = NSRect(x: 16, y: 44, width: bounds.width - 32, height: 16)
        NSColor.white.setFill()
        meterRect.fill()
        BevelRenderer.shared.drawSunkenBevel(in: meterRect, theme: theme)

        let filledW = max(0, min(meterRect.width - 4, (meterRect.width - 4) * CGFloat(pct) / 100.0))
        NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0).setFill()
        NSRect(x: meterRect.minX + 2, y: meterRect.minY + 2, width: filledW, height: 12).fill()

        let btnRect = NSRect(x: bounds.midX - 40, y: 12, width: 80, height: 22)
        theme.surfaceColor.setFill()
        btnRect.fill()
        BevelRenderer.shared.drawRaisedBevel(in: btnRect, theme: theme)
        let bAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let bStr = NSAttributedString(string: "Close", attributes: bAttrs)
        bStr.draw(at: NSPoint(x: round(btnRect.midX - bStr.size().width / 2.0), y: btnRect.midY - 6))
    }

    override public func mouseDown(with event: NSEvent) {
        TrayFlyoutWindow.shared.hideFlyout()
    }
}
