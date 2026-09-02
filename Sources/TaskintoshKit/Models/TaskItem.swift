import AppKit

/// Represents an item displayed on the taskbar (application or window).
public struct TaskItem: Identifiable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var icon: NSImage?
    public let pid: pid_t
    public let bundleIdentifier: String?
    public var isActive: Bool
    public var isMinimized: Bool
    public var windowNumber: Int?
    public weak var runningApp: NSRunningApplication?

    public init(
        id: String,
        title: String,
        icon: NSImage? = nil,
        pid: pid_t,
        bundleIdentifier: String? = nil,
        isActive: Bool = false,
        isMinimized: Bool = false,
        windowNumber: Int? = nil,
        runningApp: NSRunningApplication? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.isActive = isActive
        self.isMinimized = isMinimized
        self.windowNumber = windowNumber
        self.runningApp = runningApp
    }

    public static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.isActive == rhs.isActive &&
        lhs.isMinimized == rhs.isMinimized
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isActive)
        hasher.combine(isMinimized)
    }
}
