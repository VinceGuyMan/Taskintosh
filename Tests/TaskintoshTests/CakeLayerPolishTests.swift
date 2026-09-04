import XCTest
import AppKit
@testable import TaskintoshKit
import ProceduralWindowsUpdate

final class CakeLayerPolishTests: XCTestCase {

    // MARK: - 1. Pinned Programs Manager Historical Defaults

    func testPinnedProgramsManagerHistoricalDefaultsPerEra() {
        let manager = PinnedProgramsManager.shared

        // Windows XP
        let xpDefaults = manager.defaultPrograms(for: "org.taskintosh.era.windowsxp")
        XCTAssertGreaterThanOrEqual(xpDefaults.count, 6)
        let xpIDs = xpDefaults.map { $0.id }
        XCTAssertTrue(xpIDs.contains("xp.internet"), "XP defaults must contain Internet")
        XCTAssertTrue(xpIDs.contains("xp.email"), "XP defaults must contain Email")
        XCTAssertTrue(xpIDs.contains("xp.update"), "XP defaults must contain Windows Update")
        XCTAssertTrue(xpIDs.contains("xp.terminal"), "XP defaults must contain Terminal")

        // Windows 7
        let w7Defaults = manager.defaultPrograms(for: "org.taskintosh.era.windows7")
        XCTAssertGreaterThanOrEqual(w7Defaults.count, 6)
        let w7IDs = w7Defaults.map { $0.id }
        XCTAssertTrue(w7IDs.contains("w7.safari"), "Win7 defaults must contain Safari")
        XCTAssertTrue(w7IDs.contains("w7.vscode"), "Win7 defaults must contain VS Code")
        XCTAssertTrue(w7IDs.contains("w7.terminal"), "Win7 defaults must contain Terminal")
        XCTAssertTrue(w7IDs.contains("w7.calc"), "Win7 defaults must contain Calculator")

        // Windows 8 & 8.1
        let w8Defaults = manager.defaultPrograms(for: "org.taskintosh.era.windows8")
        XCTAssertGreaterThanOrEqual(w8Defaults.count, 12)
        let w8Groups = Set(w8Defaults.compactMap { $0.groupName })
        XCTAssertTrue(w8Groups.contains("Apps"), "Win8 defaults must have Apps group")
        XCTAssertTrue(w8Groups.contains("macOS Locations"), "Win8 defaults must have macOS Locations group")
        XCTAssertTrue(w8Groups.contains("Control & Tools"), "Win8 defaults must have Control & Tools group")
        XCTAssertTrue(w8Groups.contains("Power"), "Win8 defaults must have Power group")
        XCTAssertTrue(w8Defaults.contains { $0.isWide }, "Win8 defaults must have wide tiles")

        // Windows 10
        let w10Defaults = manager.defaultPrograms(for: "org.taskintosh.era.windows10")
        XCTAssertGreaterThanOrEqual(w10Defaults.count, 8)
        let w10IDs = w10Defaults.map { $0.id }
        XCTAssertTrue(w10IDs.contains("w10.browser"), "Win10 defaults must contain browser tile")
        XCTAssertTrue(w10IDs.contains("w10.terminal"), "Win10 defaults must contain terminal tile")
        XCTAssertTrue(w10Defaults.contains { $0.isWide }, "Win10 defaults must have wide tiles")

        // Windows 11
        let w11Defaults = manager.defaultPrograms(for: "org.taskintosh.era.windows11")
        XCTAssertEqual(w11Defaults.count, 12, "Win11 defaults must have exactly 12 pinned apps (6x2 grid)")
        let w11IDs = w11Defaults.map { $0.id }
        XCTAssertTrue(w11IDs.contains("w11.safari"), "Win11 defaults must contain Safari")
        XCTAssertTrue(w11IDs.contains("w11.terminal"), "Win11 defaults must contain Terminal")
    }

    // MARK: - 2. Pinned Programs Isolation, Pinning & Duplicate Prevention

    func testPinnedProgramsManagerIsolatedPinAndDuplicateHandling() {
        let suiteName = "CakeLayerTestDefaults_\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }
        defer {
            testDefaults.removePersistentDomain(forName: suiteName)
        }

        let isolatedManager = PinnedProgramsManager(userDefaults: testDefaults)
        let testEra = "org.taskintosh.era.test_era"

        // Initial query should return fallback defaults
        let initial = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertFalse(initial.isEmpty)

        // Pin new custom item
        let customItem = PinnedProgramItem(
            id: "custom.test.app",
            title: "Test Application",
            subtitle: "Unit Test",
            path: "/Applications/Test.app",
            iconType: "terminal",
            isWide: false
        )
        isolatedManager.pin(item: customItem, in: testEra)

        XCTAssertTrue(isolatedManager.isPinned(id: "custom.test.app", in: testEra))
        let afterPin = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertEqual(afterPin.last?.id, "custom.test.app")

        // Re-pinning same ID should not duplicate
        let updatedItem = PinnedProgramItem(
            id: "custom.test.app",
            title: "Test Application Renamed",
            subtitle: "Unit Test 2",
            path: "/Applications/Test.app",
            iconType: "terminal",
            isWide: true
        )
        isolatedManager.pin(item: updatedItem, in: testEra)

        let afterRePin = isolatedManager.pinnedPrograms(for: testEra)
        let matches = afterRePin.filter { $0.id == "custom.test.app" }
        XCTAssertEqual(matches.count, 1, "Re-pinning item must prevent duplicates")
        XCTAssertEqual(matches.first?.title, "Test Application Renamed")
        XCTAssertEqual(matches.first?.isWide, true)
    }

    // MARK: - 3. Bounds Clamping & Reordering Safety

    func testPinnedProgramsManagerReorderingBoundsClamping() {
        let suiteName = "CakeLayerReorderTest_\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }
        defer {
            testDefaults.removePersistentDomain(forName: suiteName)
        }

        let isolatedManager = PinnedProgramsManager(userDefaults: testDefaults)
        let testEra = "org.taskintosh.era.windows7"

        let programs = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertGreaterThan(programs.count, 2)
        let originalFirst = programs[0]
        let originalLast = programs[programs.count - 1]

        // Reorder out of bounds (-50 to 999) must be clamped safely without crash
        let success = isolatedManager.reorder(fromIndex: -50, toIndex: 999, in: testEra)
        XCTAssertTrue(success, "Reordering with clamped indices should succeed")

        let reordered = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertEqual(reordered.count, programs.count, "Count must remain unchanged")
        XCTAssertEqual(reordered.last?.id, originalFirst.id, "First item should have moved to the end")

        // Test moveItem by ID
        let moveSuccess = isolatedManager.moveItem(id: originalLast.id, toIndex: 0, in: testEra)
        XCTAssertTrue(moveSuccess)
        let afterMove = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertEqual(afterMove.first?.id, originalLast.id)
    }

    // MARK: - 4. Unpin & Reset to Defaults

    func testPinnedProgramsManagerUnpinAndReset() {
        let suiteName = "CakeLayerResetTest_\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }
        defer {
            testDefaults.removePersistentDomain(forName: suiteName)
        }

        let isolatedManager = PinnedProgramsManager(userDefaults: testDefaults)
        let testEra = "org.taskintosh.era.windowsxp"

        let initial = isolatedManager.pinnedPrograms(for: testEra)
        guard let firstID = initial.first?.id else {
            XCTFail("XP programs should not be empty")
            return
        }

        isolatedManager.unpin(id: firstID, in: testEra)
        let afterUnpin = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertFalse(afterUnpin.contains { $0.id == firstID })

        // Reset to defaults
        isolatedManager.resetToDefaults(for: testEra)
        let afterReset = isolatedManager.pinnedPrograms(for: testEra)
        XCTAssertEqual(afterReset.count, isolatedManager.defaultPrograms(for: testEra).count)
        XCTAssertTrue(afterReset.contains { $0.id == firstID })
    }

    func testPinnedProgramsManagerPersistsAnIntentionallyEmptyLayout() {
        let suiteName = "CakeLayerEmptyLayoutTest_\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }
        defer {
            testDefaults.removePersistentDomain(forName: suiteName)
        }

        let manager = PinnedProgramsManager(userDefaults: testDefaults)
        let eraID = "org.taskintosh.era.windows11"

        for item in manager.pinnedPrograms(for: eraID) {
            manager.unpin(id: item.id, in: eraID)
        }

        XCTAssertEqual(manager.pinnedPrograms(for: eraID), [])

        manager.resetToDefaults(for: eraID)
        XCTAssertFalse(manager.pinnedPrograms(for: eraID).isEmpty)
    }

    // MARK: - 5. Animated Progress Bar Polish & Determinism

    func testAnimatedProgressBarDeterminismAndClamping() {
        // ChunkyProgressBar (Win95/98)
        let chunky = ChunkyProgressBar(progress: 0.65, isAnimated: true, isMarquee: false)
        XCTAssertNotNil(chunky)
        let chunkyMarquee = ChunkyProgressBar(progress: 0.0, isAnimated: true, isMarquee: true)
        XCTAssertNotNil(chunkyMarquee)

        // LunaProgressBar (XP)
        let luna = LunaProgressBar(progress: 0.45, isAnimated: true)
        XCTAssertNotNil(luna)

        // AeroProgressBar (Vista)
        let aero = AeroProgressBar(progress: 0.80, isAnimated: true)
        XCTAssertNotNil(aero)

        // Win7ProgressBar (7)
        let win7 = Win7ProgressBar(progress: 0.30, isAnimated: true)
        XCTAssertNotNil(win7)

        // MetroProgressBar (8/8.1)
        let metro = MetroProgressBar(progress: 0.50, isAnimated: true)
        XCTAssertNotNil(metro)

        // Win10DottedSpinner (10)
        let win10 = Win10DottedSpinner()
        XCTAssertNotNil(win10)

        // Win11ProgressRing (11)
        let win11 = Win11ProgressRing()
        XCTAssertNotNil(win11)
    }

    // MARK: - 6. Procedural Icons & Era Visual System

    func testProceduralEraIconsForAllEras() {
        let icons = ProceduralIcons.shared
        let allMenuTypes: [StartMenuType] = [
            .classicOneColumn,
            .twoColumnXP,
            .twoColumnGlass,
            .tileLauncher,
            .modernTiles,
            .hybridMenu,
            .centeredFlyout
        ]

        let testTypes: [SystemIconType] = [
            .programs, .documents, .myComputer, .settings, .terminal, .internet, .shutDown
        ]

        for eraType in allMenuTypes {
            for iconType in testTypes {
                let img = icons.icon(for: iconType, eraType: eraType, size: 24)
                XCTAssertGreaterThan(img.size.width, 0, "Icon for \(iconType) in \(eraType) must have valid width")
                XCTAssertGreaterThan(img.size.height, 0, "Icon for \(iconType) in \(eraType) must have valid height")
            }
        }
    }
}
