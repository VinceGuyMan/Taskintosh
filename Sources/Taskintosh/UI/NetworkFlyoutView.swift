import AppKit
import TaskintoshKit

// MARK: - Factory for Era-Specific Network Flyout
public enum NetworkFlyoutFactory {
    public static func makeFlyout(for era: EraPackage) -> NSView {
        switch era.theme.startMenuType {
        case .classicOneColumn:
            return Win95NetworkFlyoutView()
        case .twoColumnXP:
            return WinXPNetworkFlyoutView()
        case .twoColumnGlass:
            return Win7NetworkFlyoutView()
        case .tileLauncher, .modernTiles, .hybridMenu:
            return Win10NetworkFlyoutView()
        case .centeredFlyout:
            return Win10NetworkFlyoutView()
        default:
            return Win10NetworkFlyoutView()
        }
    }
}

// Backward compatibility
public typealias NetworkFlyoutView = Win10NetworkFlyoutView

// MARK: - Windows 10 Authentic Network Flyout
public final class Win10NetworkFlyoutView: NSView {
    private var trackingArea: NSTrackingArea?
    private var hoveredRowIndex: Int? = nil
    private var refreshButtonRect: NSRect = .zero
    private var openSettingsRect: NSRect = .zero
    private var rowRects: [(index: Int, rect: NSRect, network: WiFiNetworkItem)] = []

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 380))
        SystemMonitor.shared.refreshWiFiNetworks(force: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            SystemMonitor.shared.refreshWiFiNetworks(force: true)
            updateTrackingAreas()
        }
    }

    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        let ta = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(ta)
        trackingArea = ta
    }

    override public func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        var newIndex: Int? = nil
        for row in rowRects {
            if row.rect.contains(loc) {
                newIndex = row.index
                break
            }
        }
        if newIndex != hoveredRowIndex {
            hoveredRowIndex = newIndex
            needsDisplay = true
        }
    }

    override public func mouseExited(with event: NSEvent) {
        if hoveredRowIndex != nil {
            hoveredRowIndex = nil
            needsDisplay = true
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        rowRects.removeAll()

        // 1. Dark Acrylic Background
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 0.96).setFill()
        bounds.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()

        // 2. Top Header
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: "Network & Internet", attributes: titleAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 26))

        // Refresh button (top-right)
        refreshButtonRect = NSRect(x: bounds.width - 32, y: bounds.height - 28, width: 20, height: 20)
        let refAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: SystemMonitor.shared.isScanningWiFi ? NSColor.systemBlue : NSColor.lightGray
        ]
        NSAttributedString(string: "↻", attributes: refAttrs).draw(at: NSPoint(x: refreshButtonRect.minX + 3, y: refreshButtonRect.minY + 2))

        // 3. Current Network Status Box
        let statusBoxRect = NSRect(x: 14, y: bounds.height - 86, width: bounds.width - 28, height: 52)
        NSColor.white.withAlphaComponent(0.06).setFill()
        NSBezierPath(roundedRect: statusBoxRect, xRadius: 4, yRadius: 4).fill()

        let isConn = SystemMonitor.shared.isNetworkConnected
        let currentSSID = SystemMonitor.shared.connectedSSID ?? (isConn ? "Connected Network" : "Not Connected")
        ProceduralIcons.shared.networkIcon(size: 22, color: isConn ? .white : .lightGray, isConnected: isConn, isWiFi: SystemMonitor.shared.isWiFi).draw(in: NSRect(x: statusBoxRect.minX + 10, y: statusBoxRect.midY - 11, width: 22, height: 22))

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: isConn ? NSColor(srgbRed: 0.2, green: 0.8, blue: 0.3, alpha: 1.0) : NSColor.lightGray
        ]
        NSAttributedString(string: currentSSID, attributes: nameAttrs).draw(at: NSPoint(x: statusBoxRect.minX + 38, y: statusBoxRect.midY + 1))
        let subText = isConn ? "Connected, secured • Internet access" : "No Internet access available"
        NSAttributedString(string: subText, attributes: descAttrs).draw(at: NSPoint(x: statusBoxRect.minX + 38, y: statusBoxRect.midY - 14))

        // 4. Available Networks Section
        let networks = SystemMonitor.shared.availableWiFiNetworks
        let secTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.lightGray
        ]
        let netCountText = networks.isEmpty ? (SystemMonitor.shared.isScanningWiFi ? "Scanning for networks..." : "Wi-Fi Networks") : "Available Wi-Fi Networks (\(networks.count))"
        NSAttributedString(string: netCountText, attributes: secTitleAttrs).draw(at: NSPoint(x: 16, y: bounds.height - 108))

        var curY = bounds.height - 140
        let rowH: CGFloat = 28
        let maxRows = 6

        for (idx, net) in networks.prefix(maxRows).enumerated() {
            let rowRect = NSRect(x: 14, y: curY, width: bounds.width - 28, height: rowH)
            rowRects.append((index: idx, rect: rowRect, network: net))

            if hoveredRowIndex == idx {
                NSColor.white.withAlphaComponent(0.12).setFill()
                NSBezierPath(roundedRect: rowRect, xRadius: 4, yRadius: 4).fill()
            } else if net.isConnected {
                NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 0.2).setFill()
                NSBezierPath(roundedRect: rowRect, xRadius: 4, yRadius: 4).fill()
            }

            // Signal bars icon
            let sigColor: NSColor = net.isConnected ? .white : NSColor(white: 0.85, alpha: 1.0)
            ProceduralIcons.shared.networkIcon(size: 16, color: sigColor, isConnected: true, isWiFi: true).draw(in: NSRect(x: rowRect.minX + 8, y: rowRect.midY - 8, width: 16, height: 16))

            // SSID Name
            let netNameAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: net.isConnected ? .semibold : .regular),
                .foregroundColor: NSColor.white
            ]
            let truncatedSSID = (net.ssid.count > 24) ? String(net.ssid.prefix(22)) + "…" : net.ssid
            NSAttributedString(string: truncatedSSID, attributes: netNameAttrs).draw(at: NSPoint(x: rowRect.minX + 32, y: rowRect.midY - 6))

            // Lock indicator
            if net.isSecured {
                let lockAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.lightGray]
                NSAttributedString(string: "🔒", attributes: lockAttrs).draw(at: NSPoint(x: rowRect.maxX - 48, y: rowRect.midY - 6))
            }

            if net.isConnected {
                let connAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9, weight: .medium), .foregroundColor: NSColor(srgbRed: 0.3, green: 0.85, blue: 1.0, alpha: 1.0)]
                NSAttributedString(string: "Connected", attributes: connAttrs).draw(at: NSPoint(x: rowRect.maxX - 68, y: rowRect.midY - 6))
            }

            curY -= (rowH + 2)
        }

        // 5. Quick Actions Row
        let tileY: CGFloat = 46
        let tileW: CGFloat = 88
        let tileH: CGFloat = 34

        // Wi-Fi Tile
        let wifiTile = NSRect(x: 14, y: tileY, width: tileW, height: tileH)
        NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: wifiTile, xRadius: 4, yRadius: 4).fill()
        let qAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Wi-Fi\nOn", attributes: qAttrs).draw(at: NSPoint(x: wifiTile.minX + 8, y: wifiTile.minY + 4))

        // Airplane Mode Tile
        let airTile = NSRect(x: 14 + tileW + 8, y: tileY, width: tileW, height: tileH)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: airTile, xRadius: 4, yRadius: 4).fill()
        NSAttributedString(string: "Airplane\nOff", attributes: qAttrs).draw(at: NSPoint(x: airTile.minX + 8, y: airTile.minY + 4))

        // Hotspot Tile
        let hotTile = NSRect(x: 14 + (tileW + 8) * 2, y: tileY, width: tileW, height: tileH)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: hotTile, xRadius: 4, yRadius: 4).fill()
        NSAttributedString(string: "Hotspot\nOff", attributes: qAttrs).draw(at: NSPoint(x: hotTile.minX + 8, y: hotTile.minY + 4))

        // 6. Bottom Settings Link
        let linkY: CGFloat = 14
        openSettingsRect = NSRect(x: 14, y: linkY, width: bounds.width - 28, height: 22)
        let linkAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor(srgbRed: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
        ]
        let linkStr = NSAttributedString(string: "Network & Internet settings", attributes: linkAttrs)
        linkStr.draw(at: NSPoint(x: openSettingsRect.minX + 2, y: openSettingsRect.minY + 4))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)

        // 1. Refresh Button Click
        if refreshButtonRect.contains(loc) {
            SystemMonitor.shared.refreshWiFiNetworks(force: true)
            needsDisplay = true
            return
        }

        // 2. Network Item Click -> Open macOS Wi-Fi Settings safely
        for row in rowRects {
            if row.rect.contains(loc) {
                TrayFlyoutWindow.shared.hideFlyout()
                openMacOSWiFiSettings()
                return
            }
        }

        // 3. Settings link click
        if openSettingsRect.contains(loc) || loc.y < 42 {
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        }
    }

    private func openMacOSWiFiSettings() {
        let script = "tell application \"System Settings\" to activate"
        let proc = Process()
        proc.launchPath = "/usr/bin/osascript"
        proc.arguments = ["-e", script]
        try? proc.run()
        // Also open directly via url scheme
        if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Windows 7 Aero Glass Network Flyout
public final class Win7NetworkFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 310, height: 320))
        SystemMonitor.shared.refreshWiFiNetworks(force: false)
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

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.white]
        let isConn = SystemMonitor.shared.isNetworkConnected
        let ssid = SystemMonitor.shared.connectedSSID ?? (isConn ? "Network" : "Not Connected")
        NSAttributedString(string: "Currently connected to:", attributes: titleAttrs).draw(at: NSPoint(x: 14, y: bounds.height - 24))

        let connBox = NSRect(x: 14, y: bounds.height - 68, width: bounds.width - 28, height: 40)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: connBox, xRadius: 4, yRadius: 4).fill()
        ProceduralIcons.shared.networkIcon(size: 20, color: .white, isConnected: isConn, isWiFi: true).draw(in: NSRect(x: connBox.minX + 8, y: connBox.midY - 10, width: 20, height: 20))
        NSAttributedString(string: ssid, attributes: titleAttrs).draw(at: NSPoint(x: connBox.minX + 36, y: connBox.midY + 1))
        let descAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.lightGray]
        NSAttributedString(string: isConn ? "Internet access" : "No connection", attributes: descAttrs).draw(at: NSPoint(x: connBox.minX + 36, y: connBox.midY - 12))

        // Wireless Network Connection Header
        let secAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: NSColor.white]
        NSAttributedString(string: "Wireless Network Connection", attributes: secAttrs).draw(at: NSPoint(x: 14, y: bounds.height - 92))

        // Network list
        var curY = bounds.height - 122
        let networks = SystemMonitor.shared.availableWiFiNetworks
        for net in networks.prefix(5) {
            let rowRect = NSRect(x: 14, y: curY, width: bounds.width - 28, height: 24)
            if net.isConnected {
                NSColor.white.withAlphaComponent(0.15).setFill()
                NSBezierPath(roundedRect: rowRect, xRadius: 3, yRadius: 3).fill()
            }
            ProceduralIcons.shared.networkIcon(size: 14, color: .white, isConnected: true, isWiFi: true).draw(in: NSRect(x: rowRect.minX + 6, y: rowRect.midY - 7, width: 14, height: 14))
            let nAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.white]
            let tSSID = net.ssid.count > 22 ? String(net.ssid.prefix(20)) + "…" : net.ssid
            NSAttributedString(string: tSSID, attributes: nAttrs).draw(at: NSPoint(x: rowRect.minX + 26, y: rowRect.midY - 6))

            if net.isConnected {
                let badgeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor(srgbRed: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)]
                NSAttributedString(string: "Connected", attributes: badgeAttrs).draw(at: NSPoint(x: rowRect.maxX - 62, y: rowRect.midY - 5))
            } else if net.isSecured {
                let lockAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.lightGray]
                NSAttributedString(string: "🔒", attributes: lockAttrs).draw(at: NSPoint(x: rowRect.maxX - 24, y: rowRect.midY - 5))
            }
            curY -= 28
        }

        // Bottom link
        let divY: CGFloat = 38
        NSColor(white: 1.0, alpha: 0.15).setFill()
        NSRect(x: 12, y: divY, width: bounds.width - 24, height: 1).fill()

        let linkAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor(srgbRed: 0.45, green: 0.78, blue: 1.0, alpha: 1.0)]
        NSAttributedString(string: "Open Network and Sharing Center", attributes: linkAttrs).draw(at: NSPoint(x: 14, y: 12))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        TrayFlyoutWindow.shared.hideFlyout()
        if loc.y < 38 {
            MacOSLocationsService.shared.openSystemSettings()
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Windows XP Luna Network Flyout
public final class WinXPNetworkFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 200))
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
        NSAttributedString(string: "Wireless Network Connection Status", attributes: titleAttrs).draw(at: NSPoint(x: 12, y: headRect.midY - 6))

        let isConn = SystemMonitor.shared.isNetworkConnected
        let ssid = SystemMonitor.shared.connectedSSID ?? (isConn ? "Connected" : "Not Connected")
        ProceduralIcons.shared.networkIcon(size: 28, color: .black, isConnected: isConn, isWiFi: true).draw(in: NSRect(x: 16, y: bounds.height - 70, width: 28, height: 28))

        let tAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let dAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
        NSAttributedString(string: ssid, attributes: tAttrs).draw(at: NSPoint(x: 52, y: bounds.height - 54))
        NSAttributedString(string: isConn ? "Status: Connected" : "Status: Disconnected", attributes: dAttrs).draw(at: NSPoint(x: 52, y: bounds.height - 68))

        // Signal strength bar
        let barRect = NSRect(x: 16, y: 70, width: bounds.width - 32, height: 14)
        NSColor.white.setFill()
        barRect.fill()
        NSColor.gray.setStroke()
        NSBezierPath(rect: barRect).stroke()
        if isConn {
            NSColor(srgbRed: 0.2, green: 0.7, blue: 0.2, alpha: 1.0).setFill()
            NSRect(x: 18, y: 72, width: (barRect.width - 4) * 0.8, height: 10).fill()
        }

        // View Wireless Networks button
        let btnRect = NSRect(x: 16, y: 16, width: bounds.width - 32, height: 26)
        let btnGrad = NSGradient(starting: NSColor(white: 0.95, alpha: 1.0), ending: NSColor(white: 0.85, alpha: 1.0))
        btnGrad?.draw(in: btnRect, angle: 90)
        NSColor.gray.setStroke()
        NSBezierPath(rect: btnRect).stroke()
        let bAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let bStr = NSAttributedString(string: "View Wireless Networks", attributes: bAttrs)
        bStr.draw(at: NSPoint(x: round(btnRect.midX - bStr.size().width / 2.0), y: btnRect.midY - 7))
    }

    override public func mouseDown(with event: NSEvent) {
        TrayFlyoutWindow.shared.hideFlyout()
        if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Windows 95 Classic Network Flyout
public final class Win95NetworkFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 160))
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = (EraManager.shared.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }) ?? EraManager.shared.activeEra).theme
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        NSAttributedString(string: "Connection Status", attributes: titleAttrs).draw(at: NSPoint(x: 12, y: bounds.height - 20))

        let isConn = SystemMonitor.shared.isNetworkConnected
        let ssid = SystemMonitor.shared.connectedSSID ?? (isConn ? "Connected to Internet" : "Disconnected")
        ProceduralIcons.shared.networkIcon(size: 24, color: .black, isConnected: isConn, isWiFi: false).draw(in: NSRect(x: 16, y: bounds.height - 56, width: 24, height: 24))

        let tAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        NSAttributedString(string: ssid, attributes: tAttrs).draw(at: NSPoint(x: 48, y: bounds.height - 46))
        let descAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
        NSAttributedString(string: isConn ? "Connected at 100.0 Mbps" : "No dial-up or LAN carrier", attributes: descAttrs).draw(at: NSPoint(x: 48, y: bounds.height - 60))

        // Buttons
        let btnRect = NSRect(x: bounds.midX - 50, y: 16, width: 100, height: 24)
        theme.surfaceColor.setFill()
        btnRect.fill()
        BevelRenderer.shared.drawRaisedBevel(in: btnRect, theme: theme)
        let btnAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let btnStr = NSAttributedString(string: "Disconnect", attributes: btnAttrs)
        btnStr.draw(at: NSPoint(x: round(btnRect.midX - btnStr.size().width / 2.0), y: btnRect.midY - 7))
    }

    override public func mouseDown(with event: NSEvent) {
        TrayFlyoutWindow.shared.hideFlyout()
        MacOSLocationsService.shared.openSystemSettings()
    }
}
