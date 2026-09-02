import AppKit
import ApplicationServices

public final class WindowAccessibilityBridge {
    public static let shared = WindowAccessibilityBridge()

    private init() {}

    /// Checks if Accessibility permissions are currently granted for this process.
    public var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user for Accessibility permission via system prompt.
    public func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Opens macOS System Settings -> Privacy & Security -> Accessibility.
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Retrieves window titles for a given process PID if Accessibility is available.
    public func windowTitles(for pid: pid_t) -> [String] {
        guard isAccessibilityTrusted else { return [] }

        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)

        guard result == .success, let windows = value as? [AXUIElement] else { return [] }

        var titles: [String] = []
        for window in windows {
            var titleVal: AnyObject?
            if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleVal) == .success,
               let title = titleVal as? String, !title.isEmpty {
                titles.append(title)
            }
        }
        return titles
    }
}
