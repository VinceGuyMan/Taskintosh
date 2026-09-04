import XCTest
import AppKit
@testable import TaskintoshKit

final class StartMenuTests: XCTestCase {
    func testAllSixErasHaveDistinctConfiguredMenuTypes() {
        let manager = EraManager.shared
        XCTAssertEqual(manager.availableEras.count, 6, "Must have exactly 6 core eras loaded.")

        let win95 = manager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows95" }
        let winXP = manager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windowsxp" }
        let win7 = manager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows7" }
        let win8 = manager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows8" }
        let win10 = manager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows10" }
        let win11 = manager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows11" }

        XCTAssertEqual(win95?.theme.startMenuType, .classicOneColumn)
        XCTAssertEqual(winXP?.theme.startMenuType, .twoColumnXP)
        XCTAssertEqual(win7?.theme.startMenuType, .twoColumnGlass)
        XCTAssertEqual(win8?.theme.startMenuType, .tileLauncher)
        XCTAssertEqual(win10?.theme.startMenuType, .hybridMenu)
        XCTAssertEqual(win11?.theme.startMenuType, .centeredFlyout)
    }

    func testMacOSLocationsServicePaths() {
        let loc = MacOSLocationsService.shared
        XCTAssertTrue(FileManager.default.fileExists(atPath: loc.homeURL.path), "Home folder must exist.")
        XCTAssertTrue(loc.desktopURL.path.contains("/Desktop"), "Desktop URL must contain /Desktop")
        XCTAssertTrue(loc.documentsURL.path.contains("/Documents"), "Documents URL must contain /Documents")
        XCTAssertTrue(loc.downloadsURL.path.contains("/Downloads"), "Downloads URL must contain /Downloads")
        XCTAssertTrue(FileManager.default.fileExists(atPath: loc.applicationsURL.path), "/Applications folder must exist.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: loc.utilitiesURL.path), "Utilities folder must exist.")
    }

    func testUserLibraryVsSystemLibraryDistinction() {
        let loc = MacOSLocationsService.shared
        let userLib = loc.userLibraryURL
        let sysLib = loc.systemLibraryURL

        XCTAssertNotEqual(userLib.path, sysLib.path, "User Library and System Library must resolve to different paths!")
        XCTAssertEqual(sysLib.path, "/Library", "System Library must be /Library")
        XCTAssertTrue(userLib.path.hasPrefix("/Users/"), "User Library must be located inside the user's home directory.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: userLib.path), "User Library must exist.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sysLib.path), "System Library must exist.")
    }

    func testMissingFolderGracefulHandling() {
        let loc = MacOSLocationsService.shared
        let bogusURL = URL(fileURLWithPath: "/tmp/nonexistent_test_folder_\(UUID().uuidString)")

        // Calling openURL and revealInFinder on non-existent paths must not crash
        loc.openURL(bogusURL)
        loc.revealInFinder(url: bogusURL)
    }

    func testSearchEngineFiltering() {
        let search = MenuSearchEngine.shared
        let dummyApps = [
            CatalogApp(id: "/Applications/Safari.app", name: "Safari", url: URL(fileURLWithPath: "/Applications/Safari.app"), icon: NSImage(), category: "Programs"),
            CatalogApp(id: "/Applications/Calculator.app", name: "Calculator", url: URL(fileURLWithPath: "/Applications/Calculator.app"), icon: NSImage(), category: "Accessories"),
            CatalogApp(id: "/System/Applications/Utilities/Terminal.app", name: "Terminal", url: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"), icon: NSImage(), category: "Accessories/Utilities")
        ]

        let results = search.search(query: "term", apps: dummyApps)
        XCTAssertFalse(results.isEmpty, "Search for 'term' must return results.")
        XCTAssertTrue(results.contains { $0.title.lowercased().contains("terminal") }, "Search results must contain Terminal.")

        let locResults = search.search(query: "library", apps: dummyApps)
        XCTAssertTrue(locResults.contains { $0.title == "User Library" }, "Search results must include User Library.")
        XCTAssertTrue(locResults.contains { $0.title == "System Library" }, "Search results must include System Library.")
    }

    func testStartMenuItemAndGroupConstruction() {
        var actionExecuted = false
        let item = StartMenuItem(
            id: "test-item",
            title: "Test Action",
            subtitle: "Test Subtitle",
            icon: NSImage(),
            isDestructive: true,
            accessibleRole: .button,
            accessibleHelp: "Perform test action"
        ) {
            actionExecuted = true
        }

        XCTAssertEqual(item.id, "test-item")
        XCTAssertEqual(item.title, "Test Action")
        XCTAssertEqual(item.subtitle, "Test Subtitle")
        XCTAssertTrue(item.isDestructive)
        XCTAssertEqual(item.accessibleRole, .button)
        XCTAssertEqual(item.accessibleHelp, "Perform test action")

        item.action()
        XCTAssertTrue(actionExecuted, "Item action must execute cleanly.")

        let group = StartMenuGroup(title: "Test Group", items: [item])
        XCTAssertEqual(group.title, "Test Group")
        XCTAssertEqual(group.items.count, 1)
    }

    func testVolumeItemsAndExternalVolumeListing() {
        let loc = MacOSLocationsService.shared
        let volumes = loc.externalVolumes()
        // Volumes listing should return an array without crashing
        for vol in volumes {
            XCTAssertFalse(vol.name.isEmpty)
            XCTAssertNotEqual(vol.url.path, "/", "External volumes should exclude root filesystem.")
        }
    }

    func testUnifiedSystemTrayClusterAndCanonicalSizes() {
        let win11 = EraManager.shared.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows11" }
        XCTAssertEqual(win11?.behaviors.unifiedSystemTrayCluster, true)

        let win10 = EraManager.shared.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows10" }
        XCTAssertEqual(win10?.behaviors.unifiedSystemTrayCluster, false)

        let win7 = EraManager.shared.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows7" }
        XCTAssertEqual(win7?.behaviors.unifiedSystemTrayCluster, false)
    }

    func testTaskbarSizePresets() {
        XCTAssertEqual(TaskbarSizePreset.allCases.count, 3)
        XCTAssertEqual(TaskbarSizePreset.small.displayName, "Small Icons / Compact")
        XCTAssertEqual(TaskbarSizePreset.normal.displayName, "Standard (Default)")
        XCTAssertEqual(TaskbarSizePreset.large.displayName, "Large Icons / Expanded")

        let config = EraLayoutConfig(taskbarHeight: 30)
        let hSmall = config.taskbarHeight(for: .small)
        let hNormal = config.taskbarHeight(for: .normal)
        let hLarge = config.taskbarHeight(for: .large)

        XCTAssertLessThan(hSmall, hNormal)
        XCTAssertGreaterThan(hLarge, hNormal)
    }

    func testStartMenuSearchEngineResults() {
        let engine = StartMenuSearchEngine.shared
        let results = engine.search(query: "set")
        XCTAssertFalse(results.isEmpty, "Search for 'set' should find System Settings / settings items")

        let settingMatch = results.first { $0.category == .settings }
        XCTAssertNotNil(settingMatch)
        XCTAssertTrue(settingMatch?.title.lowercased().contains("set") == true)

        let docResults = engine.search(query: "doc")
        XCTAssertFalse(docResults.isEmpty, "Search for 'doc' should find Documents folder or files")
    }

    func testProceduralEraIconsForAllEras() {
        let icons = ProceduralIcons.shared
        let allEras = EraManager.shared.availableEras
        XCTAssertEqual(allEras.count, 6)

        for era in allEras {
            for type in SystemIconType.allCases {
                let img = icons.icon(for: type, era: era, size: 24)
                XCTAssertGreaterThan(img.size.width, 0, "Icon for \(type) in \(era.manifest.id) must have valid width")
                XCTAssertGreaterThan(img.size.height, 0, "Icon for \(type) in \(era.manifest.id) must have valid height")
            }
        }
    }
}
