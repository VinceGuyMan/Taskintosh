import AppKit
import TaskintoshKit

// MARK: - Factory for Era-Specific Clock Flyout
public enum ClockFlyoutFactory {
    public static func makeFlyout(for era: EraPackage) -> NSView {
        switch era.theme.startMenuType {
        case .classicOneColumn:
            return Win95ClockFlyoutView()
        case .twoColumnXP:
            return WinXPClockFlyoutView()
        case .twoColumnGlass:
            return Win7ClockFlyoutView()
        case .tileLauncher, .modernTiles, .hybridMenu:
            return Win10ClockFlyoutView()
        case .centeredFlyout:
            return Win11ClockFlyoutView()
        default:
            return Win10ClockFlyoutView()
        }
    }
}

// MARK: - Dedicated Calendar Grid Renderer
private func drawExplicitMonthCalendarGrid(
    in rect: NSRect,
    headerY: CGFloat,
    firstRowY: CGFloat,
    rowHeight: CGFloat,
    isDark: Bool,
    accentColor: NSColor
) {
    let cal = Calendar.current
    let now = Date()
    let comps = cal.dateComponents([.year, .month, .day], from: now)
    guard let currentDay = comps.day,
          let firstOfMonth = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: 1)) else { return }

    let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth) // 1=Sun, 7=Sat
    let rangeOfDays = cal.range(of: .day, in: .month, for: now) ?? 1..<31

    let dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    let colW = rect.width / 7.0

    // Day Headers
    let headerAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 10),
        .foregroundColor: isDark ? NSColor.lightGray : NSColor.darkGray
    ]
    for (i, name) in dayNames.enumerated() {
        let x = rect.minX + CGFloat(i) * colW
        let str = NSAttributedString(string: name, attributes: headerAttrs)
        str.draw(at: NSPoint(x: round(x + (colW - str.size().width) / 2.0), y: headerY))
    }

    // Days Grid
    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10),
        .foregroundColor: isDark ? NSColor.white : NSColor.black
    ]
    let todayAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 10),
        .foregroundColor: NSColor.white
    ]

    var col = weekdayOfFirst - 1
    var row = 0

    for day in rangeOfDays {
        let x = rect.minX + CGFloat(col) * colW
        let y = firstRowY - CGFloat(row) * rowHeight
        let cellW = min(colW - 2, rowHeight)
        let cellRect = NSRect(
            x: round(x + (colW - cellW) / 2.0),
            y: round(y - 1),
            width: round(cellW),
            height: round(rowHeight - 2)
        )

        if day == currentDay {
            accentColor.setFill()
            NSBezierPath(roundedRect: cellRect, xRadius: 3, yRadius: 3).fill()
            let str = NSAttributedString(string: "\(day)", attributes: todayAttrs)
            str.draw(at: NSPoint(x: round(x + (colW - str.size().width) / 2.0), y: y))
        } else {
            let str = NSAttributedString(string: "\(day)", attributes: textAttrs)
            str.draw(at: NSPoint(x: round(x + (colW - str.size().width) / 2.0), y: y))
        }

        col += 1
        if col == 7 {
            col = 0
            row += 1
        }
    }
}

// MARK: - Analog Clock Face
private func drawAnalogClockFace(center: NSPoint, radius: CGFloat, isDark: Bool) {
    let now = Date()
    let cal = Calendar.current
    let comps = cal.dateComponents([.hour, .minute, .second], from: now)
    let hour = CGFloat(comps.hour ?? 12)
    let minute = CGFloat(comps.minute ?? 0)
    let second = CGFloat(comps.second ?? 0)

    // Face circle
    (isDark ? NSColor(srgbRed: 0.16, green: 0.20, blue: 0.28, alpha: 1.0) : NSColor.white).setFill()
    let face = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    face.fill()
    (isDark ? NSColor(white: 1.0, alpha: 0.4) : NSColor.black).setStroke()
    face.lineWidth = 1.5
    face.stroke()

    // 12 hour ticks
    for i in 0..<12 {
        let angle = CGFloat(i) * (.pi / 6.0)
        let isMajor = (i % 3 == 0)
        let tickLen: CGFloat = isMajor ? 5.0 : 3.0
        let innerR = radius - tickLen - 2
        let p1 = NSPoint(x: center.x + innerR * sin(angle), y: center.y + innerR * cos(angle))
        let p2 = NSPoint(x: center.x + (radius - 2) * sin(angle), y: center.y + (radius - 2) * cos(angle))
        let tick = NSBezierPath()
        tick.move(to: p1)
        tick.line(to: p2)
        (isDark ? NSColor.lightGray : NSColor.black).setStroke()
        tick.lineWidth = isMajor ? 1.5 : 1.0
        tick.stroke()
    }

    // Hour hand
    let hAngle = (hour + minute / 60.0) * (.pi / 6.0)
    let hPath = NSBezierPath()
    hPath.move(to: center)
    hPath.line(to: NSPoint(x: center.x + (radius * 0.52) * sin(hAngle), y: center.y + (radius * 0.52) * cos(hAngle)))
    (isDark ? NSColor.white : NSColor.black).setStroke()
    hPath.lineWidth = 2.4
    hPath.stroke()

    // Minute hand
    let mAngle = (minute + second / 60.0) * (.pi / 30.0)
    let mPath = NSBezierPath()
    mPath.move(to: center)
    mPath.line(to: NSPoint(x: center.x + (radius * 0.75) * sin(mAngle), y: center.y + (radius * 0.75) * cos(mAngle)))
    (isDark ? NSColor.white : NSColor.black).setStroke()
    mPath.lineWidth = 1.6
    mPath.stroke()

    // Second hand
    let sAngle = second * (.pi / 30.0)
    let sPath = NSBezierPath()
    sPath.move(to: center)
    sPath.line(to: NSPoint(x: center.x + (radius * 0.82) * sin(sAngle), y: center.y + (radius * 0.82) * cos(sAngle)))
    NSColor.systemRed.setStroke()
    sPath.lineWidth = 1.0
    sPath.stroke()

    // Center pivot
    NSColor.black.setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)).fill()
}

// MARK: - Windows 95 Date/Time Flyout
public final class Win95ClockFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 290, height: 210))
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let theme = (EraManager.shared.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }) ?? EraManager.shared.activeEra).theme
        theme.surfaceColor.setFill()
        bounds.fill()
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        // Title Header
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        NSAttributedString(string: "Date & Time Properties", attributes: titleAttrs).draw(at: NSPoint(x: 12, y: bounds.height - 20))

        // Month Year header
        let myStr = NSAttributedString(string: SystemMonitor.shared.monthYearString, attributes: titleAttrs)
        myStr.draw(at: NSPoint(x: 145, y: bounds.height - 38))

        // Left: Analog Clock
        let clockCenter = NSPoint(x: 65, y: 108)
        drawAnalogClockFace(center: clockCenter, radius: 44, isDark: false)

        // Time text below clock
        let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let timeStr = NSAttributedString(string: SystemMonitor.shared.timeString, attributes: timeAttrs)
        timeStr.draw(at: NSPoint(x: round(clockCenter.x - timeStr.size().width / 2.0), y: 34))

        // Right: Calendar Grid
        let calRect = NSRect(x: 135, y: 20, width: 145, height: 145)
        drawExplicitMonthCalendarGrid(
            in: calRect,
            headerY: 142,
            firstRowY: 122,
            rowHeight: 18,
            isDark: false,
            accentColor: NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)
        )
    }
}

// MARK: - Windows XP Date/Time Flyout
public final class WinXPClockFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 300, height: 220))
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
        NSAttributedString(string: "Date and Time Properties", attributes: titleAttrs).draw(at: NSPoint(x: 12, y: headRect.midY - 6))

        // Month Year header
        let myAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor(srgbRed: 0.08, green: 0.22, blue: 0.60, alpha: 1.0)]
        let myStr = NSAttributedString(string: SystemMonitor.shared.monthYearString, attributes: myAttrs)
        myStr.draw(at: NSPoint(x: 150, y: bounds.height - 44))

        // Left: Analog Clock
        let clockCenter = NSPoint(x: 68, y: 112)
        drawAnalogClockFace(center: clockCenter, radius: 46, isDark: false)

        // Time text below clock
        let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let timeStr = NSAttributedString(string: SystemMonitor.shared.timeString, attributes: timeAttrs)
        timeStr.draw(at: NSPoint(x: round(clockCenter.x - timeStr.size().width / 2.0), y: 34))

        // Right: Calendar Grid
        let calRect = NSRect(x: 140, y: 22, width: 150, height: 145)
        drawExplicitMonthCalendarGrid(
            in: calRect,
            headerY: 145,
            firstRowY: 124,
            rowHeight: 18,
            isDark: false,
            accentColor: NSColor(srgbRed: 0.18, green: 0.44, blue: 0.90, alpha: 1.0)
        )
    }
}

// MARK: - Windows 7 Aero Glass Date & Time Flyout
public final class Win7ClockFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 330, height: 260))
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
        let bPath = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        bPath.lineWidth = 1
        bPath.stroke()

        // ----------------------------------------------------
        // Left Column: Analog Clock & Digital Time
        // ----------------------------------------------------
        let leftCenterX: CGFloat = 72
        let clockCenter = NSPoint(x: leftCenterX, y: 160)
        drawAnalogClockFace(center: clockCenter, radius: 46, isDark: true)

        // Digital Time string directly below clock
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let timeStr = NSAttributedString(string: SystemMonitor.shared.timeString, attributes: timeAttrs)
        timeStr.draw(at: NSPoint(x: round(leftCenterX - timeStr.size().width / 2.0), y: 88))

        // Time Zone / Location label
        let tzAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white.withAlphaComponent(0.7)
        ]
        let tzStr = NSAttributedString(string: "Local Time", attributes: tzAttrs)
        tzStr.draw(at: NSPoint(x: round(leftCenterX - tzStr.size().width / 2.0), y: 68))

        // Vertical divider separating columns
        NSColor(white: 1.0, alpha: 0.12).setFill()
        NSRect(x: 146, y: 52, width: 1, height: 188).fill()

        // ----------------------------------------------------
        // Right Column: Month Header & Calendar
        // ----------------------------------------------------
        let myAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        let myStr = NSAttributedString(string: SystemMonitor.shared.monthYearString, attributes: myAttrs)
        myStr.draw(at: NSPoint(x: 160, y: 224))

        // Navigation chevrons (‹ ›)
        let navAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ]
        NSAttributedString(string: "‹", attributes: navAttrs).draw(at: NSPoint(x: 282, y: 223))
        NSAttributedString(string: "›", attributes: navAttrs).draw(at: NSPoint(x: 304, y: 223))

        // Calendar Grid
        let calRect = NSRect(x: 154, y: 56, width: 164, height: 155)
        drawExplicitMonthCalendarGrid(
            in: calRect,
            headerY: 198,
            firstRowY: 174,
            rowHeight: 20,
            isDark: true,
            accentColor: NSColor(srgbRed: 0.15, green: 0.55, blue: 0.95, alpha: 0.85)
        )

        // ----------------------------------------------------
        // Bottom Bar: Settings link
        // ----------------------------------------------------
        let divY: CGFloat = 42
        NSColor(white: 1.0, alpha: 0.15).setFill()
        NSRect(x: 12, y: divY, width: bounds.width - 24, height: 1).fill()

        let linkAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor(srgbRed: 0.45, green: 0.78, blue: 1.0, alpha: 1.0)
        ]
        let linkStr = NSAttributedString(string: "Change date and time settings...", attributes: linkAttrs)
        linkStr.draw(at: NSPoint(x: 16, y: 14))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 42 {
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        }
    }
}

// MARK: - Windows 10 Acrylic Calendar Flyout
public final class Win10ClockFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 360))
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Dark Acrylic Background
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 0.96).setFill()
        bounds.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()

        // ----------------------------------------------------
        // 1. Time / Date Header
        // ----------------------------------------------------
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 30, weight: .light),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: SystemMonitor.shared.timeString, attributes: timeAttrs).draw(at: NSPoint(x: 20, y: 312))

        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor(srgbRed: 0.0, green: 0.65, blue: 0.95, alpha: 1.0)
        ]
        NSAttributedString(string: SystemMonitor.shared.dateLongString, attributes: dateAttrs).draw(at: NSPoint(x: 20, y: 288))

        // Divider
        NSColor.white.withAlphaComponent(0.12).setFill()
        NSRect(x: 16, y: 276, width: bounds.width - 32, height: 1).fill()

        // ----------------------------------------------------
        // 2. Calendar Header (Month Year + Chevrons)
        // ----------------------------------------------------
        let myAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: SystemMonitor.shared.monthYearString, attributes: myAttrs).draw(at: NSPoint(x: 20, y: 246))

        let chevAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.lightGray
        ]
        NSAttributedString(string: "‹", attributes: chevAttrs).draw(at: NSPoint(x: bounds.width - 50, y: 246))
        NSAttributedString(string: "›", attributes: chevAttrs).draw(at: NSPoint(x: bounds.width - 30, y: 246))

        // ----------------------------------------------------
        // 3. Calendar Grid
        // ----------------------------------------------------
        let calRect = NSRect(x: 16, y: 52, width: bounds.width - 32, height: 180)
        drawExplicitMonthCalendarGrid(
            in: calRect,
            headerY: 220,
            firstRowY: 194,
            rowHeight: 22,
            isDark: true,
            accentColor: NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0)
        )

        // ----------------------------------------------------
        // 4. Footer & Actions
        // ----------------------------------------------------
        let footY: CGFloat = 44
        NSColor.white.withAlphaComponent(0.12).setFill()
        NSRect(x: 16, y: footY, width: bounds.width - 32, height: 1).fill()

        let footAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor(srgbRed: 0.0, green: 0.65, blue: 0.95, alpha: 1.0)
        ]
        let footStr = NSAttributedString(string: "Date and time settings", attributes: footAttrs)
        footStr.draw(at: NSPoint(x: 16, y: 16))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 44 {
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        }
    }
}

// MARK: - Windows 11 Mica Calendar Flyout
public final class Win11ClockFlyoutView: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 330, height: 360))
    }
    required init?(coder: NSCoder) { fatalError() }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(srgbRed: 0.12, green: 0.12, blue: 0.14, alpha: 0.96).setFill()
        path.fill()
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        path.stroke()

        // 1. Digital Time & Date
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: SystemMonitor.shared.timeString, attributes: timeAttrs).draw(at: NSPoint(x: 20, y: 312))

        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor(srgbRed: 0.4, green: 0.75, blue: 1.0, alpha: 1.0)
        ]
        NSAttributedString(string: SystemMonitor.shared.dateLongString, attributes: dateAttrs).draw(at: NSPoint(x: 20, y: 288))

        // Divider
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSRect(x: 16, y: 276, width: bounds.width - 32, height: 1).fill()

        // 2. Month Year header
        let myAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: SystemMonitor.shared.monthYearString, attributes: myAttrs).draw(at: NSPoint(x: 20, y: 246))

        let chevAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.lightGray
        ]
        NSAttributedString(string: "‹", attributes: chevAttrs).draw(at: NSPoint(x: bounds.width - 50, y: 246))
        NSAttributedString(string: "›", attributes: chevAttrs).draw(at: NSPoint(x: bounds.width - 30, y: 246))

        // 3. Calendar Grid
        let calRect = NSRect(x: 16, y: 52, width: bounds.width - 32, height: 180)
        drawExplicitMonthCalendarGrid(
            in: calRect,
            headerY: 220,
            firstRowY: 194,
            rowHeight: 22,
            isDark: true,
            accentColor: NSColor(srgbRed: 0.0, green: 0.47, blue: 0.84, alpha: 1.0)
        )

        // 4. Footer & Actions
        let footY: CGFloat = 44
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSRect(x: 16, y: footY, width: bounds.width - 32, height: 1).fill()

        let footAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor(srgbRed: 0.4, green: 0.75, blue: 1.0, alpha: 1.0)
        ]
        let footStr = NSAttributedString(string: "Date and time settings", attributes: footAttrs)
        footStr.draw(at: NSPoint(x: 16, y: 16))
    }

    override public func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y < 44 {
            TrayFlyoutWindow.shared.hideFlyout()
            MacOSLocationsService.shared.openSystemSettings()
        }
    }
}
