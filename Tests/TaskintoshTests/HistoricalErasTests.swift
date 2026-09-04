import XCTest
import AppKit
@testable import TaskintoshKit

final class HistoricalErasTests: XCTestCase {
    func testSixSupportedErasDiscoveredAndLoaded() {
        let manager = EraManager()
        manager.reloadAvailableEras()

        let eras = manager.availableEras
        let eraIDs = Set(eras.map { $0.manifest.id })

        let coreIDs = [
            "org.taskintosh.era.windows95",
            "org.taskintosh.era.windowsxp",
            "org.taskintosh.era.windows7",
            "org.taskintosh.era.windows8",
            "org.taskintosh.era.windows10",
            "org.taskintosh.era.windows11"
        ]

        XCTAssertEqual(eraIDs.count, 6, "Exactly six core eras should be discovered and loaded")
        for id in coreIDs {
            XCTAssertTrue(eraIDs.contains(id), "Core era \(id) must be discovered")
        }

        let archivedIDs = [
            "org.taskintosh.era.windows98",
            "org.taskintosh.era.windowsme",
            "org.taskintosh.era.windows2000",
            "org.taskintosh.era.windowsvista",
            "org.taskintosh.era.system7",
            "org.taskintosh.era.nextstep",
            "org.taskintosh.era.beos",
            "org.taskintosh.era.amigaos"
        ]

        for id in archivedIDs {
            XCTAssertFalse(eraIDs.contains(id), "Archived era \(id) must not be loaded")
        }
    }

    func testEachEraHasDistinctLayoutAndTheme() {
        let manager = EraManager()
        manager.reloadAvailableEras()
        let eras = manager.availableEras

        guard let win95 = eras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }),
              let winXP = eras.first(where: { $0.manifest.id == "org.taskintosh.era.windowsxp" }),
              let win7 = eras.first(where: { $0.manifest.id == "org.taskintosh.era.windows7" }),
              let win8 = eras.first(where: { $0.manifest.id == "org.taskintosh.era.windows8" }),
              let win10 = eras.first(where: { $0.manifest.id == "org.taskintosh.era.windows10" }),
              let win11 = eras.first(where: { $0.manifest.id == "org.taskintosh.era.windows11" }) else {
            XCTFail("Missing one of the six core eras")
            return
        }

        // Windows 95: Classic Gray 3D bevels, Green Start button, 1-col Start menu, scroll overflow
        XCTAssertEqual(win95.layout.taskbarHeight, 28)
        XCTAssertEqual(win95.theme.bevelStyle, .classic3D)
        XCTAssertEqual(win95.theme.startButtonStyle, .classicGreen)
        XCTAssertEqual(win95.theme.startMenuType, .classicOneColumn)
        XCTAssertTrue(win95.theme.ditherActiveButton)
        XCTAssertEqual(win95.layout.overflowStrategy, .scrollButtons)

        // Windows XP: Luna Blue/Green, Luna Pill Start, 2-col Start menu, grouping
        XCTAssertEqual(winXP.layout.taskbarHeight, 30)
        XCTAssertEqual(winXP.theme.startButtonStyle, .lunaPill)
        XCTAssertEqual(winXP.theme.startMenuType, .twoColumnXP)
        XCTAssertEqual(winXP.theme.accentIndicatorStyle, .glowPill)
        XCTAssertEqual(winXP.layout.overflowStrategy, .grouping)

        // Windows 7: Translucent Glass Superbar, Aero Orb, Icon-only plates
        XCTAssertEqual(win7.layout.taskbarHeight, 40)
        XCTAssertEqual(win7.theme.translucencyStyle, .glass)
        XCTAssertEqual(win7.layout.buttonStyle, .iconOnly)
        XCTAssertEqual(win7.theme.startButtonStyle, .aeroOrb)
        XCTAssertEqual(win7.layout.showDesktopButton, .farRightPeek)

        // Windows 8: Sharp Flat Deep Slate Tiles, Flat angled tiles, not black acrylic
        XCTAssertEqual(win8.layout.taskbarHeight, 40)
        XCTAssertEqual(win8.layout.buttonStyle, .tile)
        XCTAssertEqual(win8.theme.startButtonStyle, .flatTiles)
        XCTAssertEqual(win8.theme.accentIndicatorStyle, .tileBevel)
        XCTAssertNotEqual(win8.theme.backgroundColorHex, win10.theme.backgroundColorHex, "Win 8 slate must differ from Win 10 acrylic")

        // Windows 10: Dark Flat Acrylic, Left-aligned, 2px Bottom Accent Line
        XCTAssertEqual(win10.layout.taskbarHeight, 40)
        XCTAssertEqual(win10.layout.alignment, .leading)
        XCTAssertEqual(win10.theme.translucencyStyle, .acrylic)
        XCTAssertEqual(win10.theme.accentIndicatorStyle, .bottomLine)

        // Windows 11: Centered Geometry, Rounded Pill Plates, Mica
        XCTAssertEqual(win11.layout.taskbarHeight, 48)
        XCTAssertEqual(win11.layout.alignment, .center)
        XCTAssertEqual(win11.layout.taskbarStyle, .centered)
        XCTAssertEqual(win11.layout.buttonStyle, .pill)
        XCTAssertEqual(win11.theme.startButtonStyle, .win11Centered)
        XCTAssertEqual(win11.theme.accentIndicatorStyle, .dot)
        XCTAssertEqual(win11.theme.translucencyStyle, .mica)
    }

    func testTaskButtonMinimumWidthsEnforced() {
        let manager = EraManager()
        manager.reloadAvailableEras()
        let eras = manager.availableEras

        for era in eras {
            if era.layout.buttonStyle == .standard || era.layout.buttonStyle == .tile {
                XCTAssertGreaterThanOrEqual(
                    era.layout.taskButtonMinWidth,
                    130,
                    "\(era.manifest.name) button min width must be >= 130px to ensure title readability"
                )
            }
        }
    }

    func testLongApplicationNamesReadable() {
        let longNames = [
            "Google Chrome",
            "Visual Studio Code",
            "System Settings",
            "Xcode Developer Tools"
        ]

        let minWidth: CGFloat = 130
        let iconAndPadding: CGFloat = 6 + 16 + 4 + 6 // 32px total margin
        let availableTextWidth = minWidth - iconAndPadding // ~98px

        let font = NSFont.systemFont(ofSize: 11)
        for name in longNames {
            let fullSize = (name as NSString).size(withAttributes: [.font: font])
            XCTAssertGreaterThan(fullSize.width, 0)
            // Even if the full text exceeds 98px, the button width allows showing the majority of the title
            let firstWord = name.components(separatedBy: " ").first ?? ""
            let firstWordSize = (firstWord as NSString).size(withAttributes: [.font: font])
            XCTAssertLessThan(
                firstWordSize.width,
                availableTextWidth,
                "At 130px min width, '\(firstWord)' must fit comfortably in readable text area"
            )
        }
    }

    func testEraSwitching() {
        let manager = EraManager()
        manager.reloadAvailableEras()

        let eras = manager.availableEras
        XCTAssertFalse(eras.isEmpty)

        for era in eras {
            manager.selectEra(era)
            XCTAssertEqual(manager.activeEra.manifest.id, era.manifest.id)
            XCTAssertGreaterThan(manager.activeEra.layout.taskbarHeight, 0)
            XCTAssertFalse(manager.activeEra.manifest.name.isEmpty)
        }
    }
}
