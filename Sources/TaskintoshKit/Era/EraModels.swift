import AppKit

public enum TaskbarEdge: String, Codable, CaseIterable {
    case bottom
    case top
    case left
    case right
}

public enum BevelStyle: String, Codable {
    case classic3D
    case flat
    case etched
}

public enum ClickActiveAction: String, Codable {
    case minimize
    case none
}

public enum WindowGrouping: String, Codable {
    case none
    case groupWhenFull
    case alwaysGroup
}

public struct EraManifest: Codable, Equatable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let eraPeriod: String
    public let description: String
    public let minEngineVersion: String

    public init(
        id: String,
        name: String,
        version: String,
        author: String,
        eraPeriod: String,
        description: String,
        minEngineVersion: String = "1.0.0"
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.eraPeriod = eraPeriod
        self.description = description
        self.minEngineVersion = minEngineVersion
    }
}

public struct EraLayoutConfig: Codable, Equatable {
    public var defaultEdge: TaskbarEdge
    public var taskbarHeight: CGFloat
    public var itemSpacing: CGFloat
    public var paddingHorizontal: CGFloat
    public var paddingVertical: CGFloat
    public var startButtonWidth: CGFloat
    public var startButtonHeight: CGFloat?
    public var taskButtonMinWidth: CGFloat
    public var taskButtonMaxWidth: CGFloat
    public var trayPadding: CGFloat

    public init(
        defaultEdge: TaskbarEdge = .bottom,
        taskbarHeight: CGFloat = 28,
        itemSpacing: CGFloat = 2,
        paddingHorizontal: CGFloat = 2,
        paddingVertical: CGFloat = 2,
        startButtonWidth: CGFloat = 56,
        startButtonHeight: CGFloat? = nil,
        taskButtonMinWidth: CGFloat = 40,
        taskButtonMaxWidth: CGFloat = 160,
        trayPadding: CGFloat = 4
    ) {
        self.defaultEdge = defaultEdge
        self.taskbarHeight = taskbarHeight
        self.itemSpacing = itemSpacing
        self.paddingHorizontal = paddingHorizontal
        self.paddingVertical = paddingVertical
        self.startButtonWidth = startButtonWidth
        self.startButtonHeight = startButtonHeight
        self.taskButtonMinWidth = taskButtonMinWidth
        self.taskButtonMaxWidth = taskButtonMaxWidth
        self.trayPadding = trayPadding
    }
}

public struct EraVisualTheme: Codable, Equatable {
    public var backgroundColorHex: String
    public var surfaceColorHex: String
    public var lightHighlightColorHex: String
    public var shadowColorHex: String
    public var darkShadowColorHex: String
    public var textColorHex: String
    public var activeTextColorHex: String
    public var bannerStartColorHex: String
    public var bannerEndColorHex: String
    public var accentColorHex: String
    public var bevelStyle: BevelStyle
    public var ditherActiveButton: Bool
    public var fontSize: CGFloat
    public var fontName: String?
    public var startButtonText: String
    public var bannerText: String

    public init(
        backgroundColorHex: String = "#C0C0C0",
        surfaceColorHex: String = "#C0C0C0",
        lightHighlightColorHex: String = "#FFFFFF",
        shadowColorHex: String = "#808080",
        darkShadowColorHex: String = "#000000",
        textColorHex: String = "#000000",
        activeTextColorHex: String = "#000000",
        bannerStartColorHex: String = "#000080",
        bannerEndColorHex: String = "#1084D0",
        accentColorHex: String = "#000080",
        bevelStyle: BevelStyle = .classic3D,
        ditherActiveButton: Bool = true,
        fontSize: CGFloat = 11,
        fontName: String? = nil,
        startButtonText: String = "Start",
        bannerText: String = "Taskintosh 95"
    ) {
        self.backgroundColorHex = backgroundColorHex
        self.surfaceColorHex = surfaceColorHex
        self.lightHighlightColorHex = lightHighlightColorHex
        self.shadowColorHex = shadowColorHex
        self.darkShadowColorHex = darkShadowColorHex
        self.textColorHex = textColorHex
        self.activeTextColorHex = activeTextColorHex
        self.bannerStartColorHex = bannerStartColorHex
        self.bannerEndColorHex = bannerEndColorHex
        self.accentColorHex = accentColorHex
        self.bevelStyle = bevelStyle
        self.ditherActiveButton = ditherActiveButton
        self.fontSize = fontSize
        self.fontName = fontName
        self.startButtonText = startButtonText
        self.bannerText = bannerText
    }

    // Helper color accessors
    public var backgroundColor: NSColor { NSColor(hex: backgroundColorHex) ?? .lightGray }
    public var surfaceColor: NSColor { NSColor(hex: surfaceColorHex) ?? .lightGray }
    public var lightHighlightColor: NSColor { NSColor(hex: lightHighlightColorHex) ?? .white }
    public var shadowColor: NSColor { NSColor(hex: shadowColorHex) ?? .gray }
    public var darkShadowColor: NSColor { NSColor(hex: darkShadowColorHex) ?? .black }
    public var textColor: NSColor { NSColor(hex: textColorHex) ?? .black }
    public var activeTextColor: NSColor { NSColor(hex: activeTextColorHex) ?? .black }
    public var bannerStartColor: NSColor { NSColor(hex: bannerStartColorHex) ?? .blue }
    public var bannerEndColor: NSColor { NSColor(hex: bannerEndColorHex) ?? .cyan }
    public var accentColor: NSColor { NSColor(hex: accentColorHex) ?? .blue }

    public func font(size: CGFloat? = nil, weight: NSFont.Weight = .regular) -> NSFont {
        let pts = size ?? fontSize
        if let fontName = fontName, let customFont = NSFont(name: fontName, size: pts) {
            return customFont
        }
        return NSFont.systemFont(ofSize: pts, weight: weight)
    }

    public func boldFont(size: CGFloat? = nil) -> NSFont {
        font(size: size, weight: .bold)
    }
}

public struct EraBehaviorConfig: Codable, Equatable {
    public var autoHideSupported: Bool
    public var autoHideDelaySeconds: Double
    public var autoHidePeekMargin: CGFloat
    public var clickActiveAppAction: ClickActiveAction
    public var windowGrouping: WindowGrouping
    public var soundEffectsEnabled: Bool

    public init(
        autoHideSupported: Bool = true,
        autoHideDelaySeconds: Double = 0.5,
        autoHidePeekMargin: CGFloat = 2.0,
        clickActiveAppAction: ClickActiveAction = .minimize,
        windowGrouping: WindowGrouping = .none,
        soundEffectsEnabled: Bool = false
    ) {
        self.autoHideSupported = autoHideSupported
        self.autoHideDelaySeconds = autoHideDelaySeconds
        self.autoHidePeekMargin = autoHidePeekMargin
        self.clickActiveAppAction = clickActiveAppAction
        self.windowGrouping = windowGrouping
        self.soundEffectsEnabled = soundEffectsEnabled
    }
}

// NSColor Hex Extension
public extension NSColor {
    convenience init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        guard cleanHex.count == 6 || cleanHex.count == 8 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)

        if cleanHex.count == 6 {
            let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgbValue & 0x0000FF) / 255.0
            self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
        } else {
            let r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgbValue & 0x000000FF) / 255.0
            self.init(srgbRed: r, green: g, blue: b, alpha: a)
        }
    }
}
