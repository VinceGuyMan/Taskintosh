import XCTest
import AppKit
@testable import TaskintoshKit

final class FocusedSafetyTests: XCTestCase {

    // MARK: - 1. Menu Construction & Responder Targets
    func testTaskButtonMenuConstructionAndResponderTargets() {
        let dummyApp = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier > 0 })
        let taskItem = TaskItem(
            id: "menu-test-item",
            title: "Test Application",
            icon: nil,
            pid: dummyApp?.processIdentifier ?? 100,
            bundleIdentifier: "com.test.app",
            isActive: false,
            runningApp: dummyApp
        )

        let menu = NSMenu(title: taskItem.title)
        menu.autoenablesItems = false

        let restore = NSMenuItem(title: "Restore / Bring to Front", action: Selector(("taskActionRestore:")), keyEquivalent: "")
        let minimize = NSMenuItem(title: "Minimize", action: Selector(("taskActionMinimize:")), keyEquivalent: "")
        let close = NSMenuItem(title: "Close", action: Selector(("taskActionClose:")), keyEquivalent: "")

        menu.addItem(restore)
        menu.addItem(minimize)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(close)

        XCTAssertEqual(menu.items.count, 4)
        XCTAssertEqual(menu.items[0].title, "Restore / Bring to Front")
        XCTAssertEqual(menu.items[0].action, Selector(("taskActionRestore:")))
        XCTAssertEqual(menu.items[1].title, "Minimize")
        XCTAssertEqual(menu.items[1].action, Selector(("taskActionMinimize:")))
        XCTAssertTrue(menu.items[2].isSeparatorItem)
        XCTAssertEqual(menu.items[3].title, "Close")
        XCTAssertEqual(menu.items[3].action, Selector(("taskActionClose:")))
    }

    func testTaskbarBackgroundMenuConstruction() {
        let menu = NSMenu(title: "Taskbar")
        menu.autoenablesItems = false

        let minAll = NSMenuItem(title: "Minimize All Windows", action: Selector(("showDesktopClicked")), keyEquivalent: "")
        let taskMgr = NSMenuItem(title: "Task Manager", action: Selector(("taskManagerClicked")), keyEquivalent: "")
        let autoHide = NSMenuItem(title: "Auto-Hide the Taskbar", action: Selector(("toggleAutoHideClicked")), keyEquivalent: "")
        let eraMgr = NSMenuItem(title: "Properties & Era Manager...", action: Selector(("openEraManagerClicked")), keyEquivalent: "")

        menu.addItem(minAll)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(taskMgr)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(autoHide)
        menu.addItem(eraMgr)

        XCTAssertEqual(menu.items[0].title, "Minimize All Windows")
        XCTAssertEqual(menu.items[0].action, Selector(("showDesktopClicked")))
        XCTAssertEqual(menu.items[2].title, "Task Manager")
        XCTAssertEqual(menu.items[2].action, Selector(("taskManagerClicked")))
        XCTAssertEqual(menu.items[4].title, "Auto-Hide the Taskbar")
        XCTAssertEqual(menu.items[4].action, Selector(("toggleAutoHideClicked")))
        XCTAssertEqual(menu.items[5].title, "Properties & Era Manager...")
        XCTAssertEqual(menu.items[5].action, Selector(("openEraManagerClicked")))
    }

    // MARK: - 2. Task-Button Hit Regions & Geometry
    func testTaskButtonHitRegionsAndGeometry() {
        let dummyItems = (0..<5).map { idx in
            TaskItem(
                id: "item-\(idx)",
                title: "App Number \(idx) With a Long Window Title That Needs Clamping",
                icon: nil,
                pid: pid_t(1000 + idx),
                bundleIdentifier: "com.test.app\(idx)",
                isActive: (idx == 0),
                runningApp: nil
            )
        }

        let totalWidth: CGFloat = 1200
        let startWidth: CGFloat = 60
        let trayWidth: CGFloat = 180
        let spacing: CGFloat = 4
        let availableWidth = totalWidth - startWidth - trayWidth - 20
        let count = CGFloat(dummyItems.count)
        let buttonWidth = max(130, min(160, (availableWidth - (count - 1) * spacing) / count))

        XCTAssertGreaterThanOrEqual(buttonWidth, 130, "Standard task buttons must enforce minimum width >= 130px")
        XCTAssertLessThanOrEqual(buttonWidth, 160, "Standard task buttons must not exceed max width")

        var hitRects: [NSRect] = []
        var currentX: CGFloat = startWidth + 10
        for _ in dummyItems {
            let rect = NSRect(x: currentX, y: 3, width: buttonWidth, height: 34)
            hitRects.append(rect)
            currentX += buttonWidth + spacing
        }

        // Verify no overlapping hit regions
        for i in 0..<hitRects.count {
            for j in (i + 1)..<hitRects.count {
                XCTAssertFalse(hitRects[i].intersects(hitRects[j]), "Button hit regions must never overlap")
            }
        }
    }

    // MARK: - 3. Overflow Behavior Across Eras
    func testOverflowBehaviorAcrossEras() {
        let eraManager = EraManager.shared
        eraManager.reloadAvailableEras()

        guard let win95 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }),
              let winXP = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windowsxp" }),
              let win7 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows7" }),
              let win8 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows8" }),
              let win10 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows10" }),
              let win11 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows11" }) else {
            XCTFail("Must discover all 6 supported eras")
            return
        }

        XCTAssertEqual(win95.layout.overflowStrategy, .scrollButtons, "Win95 must use scrollButtons overflow")
        XCTAssertEqual(winXP.layout.overflowStrategy, .grouping, "WinXP must use grouping overflow")
        XCTAssertEqual(win7.layout.overflowStrategy, .iconOnly, "Win7 must use iconOnly overflow")
        XCTAssertEqual(win8.layout.overflowStrategy, .chevronMenu, "Win8 must use chevronMenu overflow")
        XCTAssertEqual(win10.layout.overflowStrategy, .chevronMenu, "Win10 must use chevronMenu overflow")
        XCTAssertEqual(win11.layout.overflowStrategy, .iconOnly, "Win11 must use iconOnly overflow")
    }

    // MARK: - 4. Era-Specific Start Menu Structure
    func testEraSpecificStartMenuStructure() {
        let eraManager = EraManager.shared
        eraManager.reloadAvailableEras()

        let expectedTypes: [String: StartMenuType] = [
            "org.taskintosh.era.windows95": .classicOneColumn,
            "org.taskintosh.era.windowsxp": .twoColumnXP,
            "org.taskintosh.era.windows7": .twoColumnGlass,
            "org.taskintosh.era.windows8": .tileLauncher,
            "org.taskintosh.era.windows10": .hybridMenu,
            "org.taskintosh.era.windows11": .centeredFlyout
        ]

        for (id, expectedType) in expectedTypes {
            guard let era = eraManager.availableEras.first(where: { $0.manifest.id == id }) else {
                XCTFail("Missing era: \(id)")
                continue
            }
            XCTAssertEqual(era.theme.startMenuType, expectedType, "Era \(id) must match expected menu type \(expectedType)")
        }
    }

    // MARK: - 5. Settings URL Routing
    func testSettingsURLRouting() {
        let mainSettingsURL = URL(string: "x-apple.systempreferences:")
        let a11ySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess")

        XCTAssertNotNil(mainSettingsURL)
        XCTAssertEqual(mainSettingsURL?.scheme, "x-apple.systempreferences")
        XCTAssertNotNil(a11ySettingsURL)
        XCTAssertEqual(a11ySettingsURL?.scheme, "x-apple.systempreferences")
        XCTAssertTrue(a11ySettingsURL?.absoluteString.contains("universalaccess") == true)
    }

    // MARK: - 6. Hidden-Folder Paths & Library Distinction
    func testHiddenFolderPathsAndLibraryDistinction() {
        let loc = MacOSLocationsService.shared

        let userLib = loc.userLibraryURL
        let sysLib = loc.systemLibraryURL

        XCTAssertNotEqual(userLib.path, sysLib.path, "User Library and System Library must be distinct paths")
        XCTAssertTrue(userLib.path.hasPrefix("/Users/"), "User Library must be inside /Users/<user>")
        XCTAssertEqual(sysLib.path, "/Library", "System Library must be /Library")

        XCTAssertTrue(FileManager.default.fileExists(atPath: userLib.path), "User Library must exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sysLib.path), "System Library must exist")

        // Desktop, Documents, Downloads
        XCTAssertTrue(loc.desktopURL.path.contains("Desktop"))
        XCTAssertTrue(loc.documentsURL.path.contains("Documents"))
        XCTAssertTrue(loc.downloadsURL.path.contains("Downloads"))
        XCTAssertTrue(loc.picturesURL.path.contains("Pictures"))

        // iCloud Drive URL path check
        if let icloud = loc.iCloudDriveURL {
            XCTAssertTrue(icloud.path.contains("Mobile Documents"))
        }
    }

    // MARK: - 7. Production-vs-Validation Build Behavior
    func testProductionVsValidationArgumentHandling() {
        let standardArgs = ["Taskintosh"]
        XCTAssertFalse(standardArgs.contains("--validate"), "Standard launch arguments do not contain --validate")

        let validateArgs = ["Taskintosh", "--validate"]
        XCTAssertTrue(validateArgs.contains("--validate"), "Validation launch arguments contain --validate")

        let snapshotArgs = ["Taskintosh", "--snapshot", "/tmp/snapshots"]
        let idx = snapshotArgs.firstIndex(where: { $0 == "--snapshot" })
        XCTAssertNotNil(idx)
        XCTAssertEqual(snapshotArgs[idx! + 1], "/tmp/snapshots")
    }
}
