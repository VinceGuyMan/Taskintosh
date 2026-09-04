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

public enum TaskbarStyle: String, Codable {
    case classic
    case centered
    case topMenuBar
    case verticalShelf
    case deskbar
}

public enum TaskButtonStyle: String, Codable {
    case standard
    case iconOnly
    case pill
    case tile
}

public enum TaskAlignment: String, Codable {
    case leading
    case center
    case trailing
}

public enum ShowDesktopButton: String, Codable {
    case none
    case farRightPeek
    case amigaGadget
}

public enum TranslucencyStyle: String, Codable {
    case opaque
    case glass
    case acrylic
    case mica
}

public enum AccentIndicatorStyle: String, Codable {
    case sunken
    case glowPill
    case bottomLine
    case dot
    case tileBevel
    case macCheckmark
}

public enum StartButtonStyle: String, Codable {
    case classicRect
    case classicGreen
    case lunaPill
    case aeroOrb
    case flatTiles
    case win11Centered
    case appleMenu
    case nextIcon
    case beLogo
    case amigaTitle
}

public enum OverflowStrategy: String, Codable {
    case scrollButtons
    case grouping
    case chevronMenu
    case iconOnly
}

public enum StartMenuType: String, Codable {
    case classicOneColumn
    case twoColumnXP
    case twoColumnGlass
    case tileLauncher
    case hybridMenu
    case centeredFlyout
    case modernTiles
    case appleDropdown
    case nextShelfMenu
    case beDeskbarMenu
    case amigaPullDown
}

public enum TaskbarSizePreset: String, Codable, CaseIterable {
    case small
    case normal
    case large

    public var displayName: String {
        switch self {
        case .small: return "Small Icons / Compact"
        case .normal: return "Standard (Default)"
        case .large: return "Large Icons / Expanded"
        }
    }

    public var multiplier: CGFloat {
        switch self {
        case .small: return 0.85
        case .normal: return 1.0
        case .large: return 1.25
        }
    }
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
    public var taskbarStyle: TaskbarStyle
    public var buttonStyle: TaskButtonStyle
    public var alignment: TaskAlignment
    public var cornerRadius: CGFloat
    public var quickLaunchEnabled: Bool
    public var showDesktopButton: ShowDesktopButton
    public var overflowStrategy: OverflowStrategy

    public init(
        defaultEdge: TaskbarEdge = .bottom,
        taskbarHeight: CGFloat = 28,
        itemSpacing: CGFloat = 2,
        paddingHorizontal: CGFloat = 2,
        paddingVertical: CGFloat = 2,
        startButtonWidth: CGFloat = 56,
        startButtonHeight: CGFloat? = nil,
        taskButtonMinWidth: CGFloat = 130,
        taskButtonMaxWidth: CGFloat = 160,
        trayPadding: CGFloat = 4,
        taskbarStyle: TaskbarStyle = .classic,
        buttonStyle: TaskButtonStyle = .standard,
        alignment: TaskAlignment = .leading,
        cornerRadius: CGFloat = 0,
        quickLaunchEnabled: Bool = false,
        showDesktopButton: ShowDesktopButton = .none,
        overflowStrategy: OverflowStrategy = .scrollButtons
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
        self.taskbarStyle = taskbarStyle
        self.buttonStyle = buttonStyle
        self.alignment = alignment
        self.cornerRadius = cornerRadius
        self.quickLaunchEnabled = quickLaunchEnabled
        self.showDesktopButton = showDesktopButton
        self.overflowStrategy = overflowStrategy
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultEdge = try container.decodeIfPresent(TaskbarEdge.self, forKey: .defaultEdge) ?? .bottom
        taskbarHeight = try container.decodeIfPresent(CGFloat.self, forKey: .taskbarHeight) ?? 28
        itemSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .itemSpacing) ?? 2
        paddingHorizontal = try container.decodeIfPresent(CGFloat.self, forKey: .paddingHorizontal) ?? 2
        paddingVertical = try container.decodeIfPresent(CGFloat.self, forKey: .paddingVertical) ?? 2
        startButtonWidth = try container.decodeIfPresent(CGFloat.self, forKey: .startButtonWidth) ?? 56
        startButtonHeight = try container.decodeIfPresent(CGFloat.self, forKey: .startButtonHeight)
        taskButtonMinWidth = try container.decodeIfPresent(CGFloat.self, forKey: .taskButtonMinWidth) ?? 130
        taskButtonMaxWidth = try container.decodeIfPresent(CGFloat.self, forKey: .taskButtonMaxWidth) ?? 160
        trayPadding = try container.decodeIfPresent(CGFloat.self, forKey: .trayPadding) ?? 4
        taskbarStyle = try container.decodeIfPresent(TaskbarStyle.self, forKey: .taskbarStyle) ?? .classic
        buttonStyle = try container.decodeIfPresent(TaskButtonStyle.self, forKey: .buttonStyle) ?? .standard
        alignment = try container.decodeIfPresent(TaskAlignment.self, forKey: .alignment) ?? .leading
        cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? 0
        quickLaunchEnabled = try container.decodeIfPresent(Bool.self, forKey: .quickLaunchEnabled) ?? false
        showDesktopButton = try container.decodeIfPresent(ShowDesktopButton.self, forKey: .showDesktopButton) ?? .none
        overflowStrategy = try container.decodeIfPresent(OverflowStrategy.self, forKey: .overflowStrategy) ?? (buttonStyle == .iconOnly || buttonStyle == .pill ? .iconOnly : .scrollButtons)
    }

    public func taskbarHeight(for preset: TaskbarSizePreset) -> CGFloat {
        switch preset {
        case .small:
            return max(22, round(taskbarHeight * 0.85))
        case .normal:
            return taskbarHeight
        case .large:
            return round(taskbarHeight * 1.25)
        }
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
    public var translucencyStyle: TranslucencyStyle
    public var accentIndicatorStyle: AccentIndicatorStyle
    public var startButtonStyle: StartButtonStyle
    public var startMenuType: StartMenuType

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
        bannerText: String = "Taskintosh 95",
        translucencyStyle: TranslucencyStyle = .opaque,
        accentIndicatorStyle: AccentIndicatorStyle = .sunken,
        startButtonStyle: StartButtonStyle = .classicRect,
        startMenuType: StartMenuType = .classicOneColumn
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
        self.translucencyStyle = translucencyStyle
        self.accentIndicatorStyle = accentIndicatorStyle
        self.startButtonStyle = startButtonStyle
        self.startMenuType = startMenuType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? "#C0C0C0"
        surfaceColorHex = try container.decodeIfPresent(String.self, forKey: .surfaceColorHex) ?? "#C0C0C0"
        lightHighlightColorHex = try container.decodeIfPresent(String.self, forKey: .lightHighlightColorHex) ?? "#FFFFFF"
        shadowColorHex = try container.decodeIfPresent(String.self, forKey: .shadowColorHex) ?? "#808080"
        darkShadowColorHex = try container.decodeIfPresent(String.self, forKey: .darkShadowColorHex) ?? "#000000"
        textColorHex = try container.decodeIfPresent(String.self, forKey: .textColorHex) ?? "#000000"
        activeTextColorHex = try container.decodeIfPresent(String.self, forKey: .activeTextColorHex) ?? "#000000"
        bannerStartColorHex = try container.decodeIfPresent(String.self, forKey: .bannerStartColorHex) ?? "#000080"
        bannerEndColorHex = try container.decodeIfPresent(String.self, forKey: .bannerEndColorHex) ?? "#1084D0"
        accentColorHex = try container.decodeIfPresent(String.self, forKey: .accentColorHex) ?? "#000080"
        bevelStyle = try container.decodeIfPresent(BevelStyle.self, forKey: .bevelStyle) ?? .classic3D
        ditherActiveButton = try container.decodeIfPresent(Bool.self, forKey: .ditherActiveButton) ?? true
        fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize) ?? 11
        fontName = try container.decodeIfPresent(String.self, forKey: .fontName)
        startButtonText = try container.decodeIfPresent(String.self, forKey: .startButtonText) ?? "Start"
        bannerText = try container.decodeIfPresent(String.self, forKey: .bannerText) ?? "Taskintosh 95"
        translucencyStyle = try container.decodeIfPresent(TranslucencyStyle.self, forKey: .translucencyStyle) ?? .opaque
        accentIndicatorStyle = try container.decodeIfPresent(AccentIndicatorStyle.self, forKey: .accentIndicatorStyle) ?? .sunken
        startButtonStyle = try container.decodeIfPresent(StartButtonStyle.self, forKey: .startButtonStyle) ?? .classicRect
        startMenuType = try container.decodeIfPresent(StartMenuType.self, forKey: .startMenuType) ?? .classicOneColumn
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
    public var quickLaunchSupported: Bool
    public var unifiedSystemTrayCluster: Bool

    public init(
        autoHideSupported: Bool = true,
        autoHideDelaySeconds: Double = 0.5,
        autoHidePeekMargin: CGFloat = 2.0,
        clickActiveAppAction: ClickActiveAction = .minimize,
        windowGrouping: WindowGrouping = .none,
        soundEffectsEnabled: Bool = false,
        quickLaunchSupported: Bool = false,
        unifiedSystemTrayCluster: Bool = false
    ) {
        self.autoHideSupported = autoHideSupported
        self.autoHideDelaySeconds = autoHideDelaySeconds
        self.autoHidePeekMargin = autoHidePeekMargin
        self.clickActiveAppAction = clickActiveAppAction
        self.windowGrouping = windowGrouping
        self.soundEffectsEnabled = soundEffectsEnabled
        self.quickLaunchSupported = quickLaunchSupported
        self.unifiedSystemTrayCluster = unifiedSystemTrayCluster
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autoHideSupported = try container.decodeIfPresent(Bool.self, forKey: .autoHideSupported) ?? true
        autoHideDelaySeconds = try container.decodeIfPresent(Double.self, forKey: .autoHideDelaySeconds) ?? 0.5
        autoHidePeekMargin = try container.decodeIfPresent(CGFloat.self, forKey: .autoHidePeekMargin) ?? 2.0
        clickActiveAppAction = try container.decodeIfPresent(ClickActiveAction.self, forKey: .clickActiveAppAction) ?? .minimize
        windowGrouping = try container.decodeIfPresent(WindowGrouping.self, forKey: .windowGrouping) ?? .none
        soundEffectsEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEffectsEnabled) ?? false
        quickLaunchSupported = try container.decodeIfPresent(Bool.self, forKey: .quickLaunchSupported) ?? false
        unifiedSystemTrayCluster = try container.decodeIfPresent(Bool.self, forKey: .unifiedSystemTrayCluster) ?? false
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
