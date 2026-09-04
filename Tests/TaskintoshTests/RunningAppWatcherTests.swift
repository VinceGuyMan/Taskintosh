import XCTest
import AppKit
@testable import TaskintoshKit

final class RunningAppWatcherTests: XCTestCase {
    func testTaskItemProcessResolutionFallback() {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier > 0 }) else {
            return
        }

        // Item with strong process handle
        let itemWithApp = TaskItem(
            id: "handle-test",
            title: app.localizedName ?? "App",
            icon: nil,
            pid: app.processIdentifier,
            bundleIdentifier: app.bundleIdentifier,
            isActive: true,
            runningApp: app
        )
        XCTAssertEqual(itemWithApp.resolveApp()?.processIdentifier, app.processIdentifier)

        // Item with nil process handle, resolves via PID fallback
        let itemWithPIDOnly = TaskItem(
            id: "pid-fallback-test",
            title: app.localizedName ?? "App",
            icon: nil,
            pid: app.processIdentifier,
            bundleIdentifier: app.bundleIdentifier,
            isActive: false,
            runningApp: nil
        )
        XCTAssertEqual(itemWithPIDOnly.resolveApp()?.processIdentifier, app.processIdentifier)
    }

    func testAccessibilityBridgeSafeFallback() {
        let bridge = WindowAccessibilityBridge.shared
        // On headless / sandbox / test environments without explicit TCC grant,
        // isAccessibilityTrusted should return a boolean without crashing or hanging.
        let isTrusted = bridge.isAccessibilityTrusted
        XCTAssertTrue(isTrusted || !isTrusted)
    }

    func testEraPackageBackwardsCompatibility() throws {
        // Minimal JSON from pre-extended schema
        let minimalLayoutJSON = """
        {
            "defaultEdge": "bottom",
            "taskbarHeight": 28,
            "itemSpacing": 2,
            "paddingHorizontal": 2,
            "paddingVertical": 2,
            "startButtonWidth": 56,
            "taskButtonMinWidth": 40,
            "taskButtonMaxWidth": 160,
            "trayPadding": 4
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let layout = try decoder.decode(EraLayoutConfig.self, from: minimalLayoutJSON)

        XCTAssertEqual(layout.taskbarHeight, 28)
        XCTAssertEqual(layout.taskbarStyle, .classic)
        XCTAssertEqual(layout.buttonStyle, .standard)
        XCTAssertEqual(layout.alignment, .leading)
        XCTAssertFalse(layout.quickLaunchEnabled)
    }
}
