import XCTest
import AppKit
@testable import TaskintoshKit

final class EraPackageTests: XCTestCase {
    func testDefaultEra() {
        let era = EraPackage.defaultEra()
        XCTAssertEqual(era.manifest.id, "org.taskintosh.era.windows95")
        XCTAssertEqual(era.manifest.name, "Windows 95 Classic")
        XCTAssertEqual(era.manifest.eraPeriod, "1995-1998")
        XCTAssertEqual(era.layout.defaultEdge, .bottom)
        XCTAssertEqual(era.layout.taskbarHeight, 28)
        XCTAssertEqual(era.theme.startButtonText, "Start")
        XCTAssertEqual(era.behaviors.clickActiveAppAction, .minimize)
    }

    func testManifestJSONDecoding() throws {
        let json = """
        {
          "id": "test.era",
          "name": "Test Era",
          "version": "2.0.0",
          "author": "Community",
          "eraPeriod": "1998-2000",
          "description": "Test Era Description",
          "minEngineVersion": "1.0.0"
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(EraManifest.self, from: json)
        XCTAssertEqual(manifest.id, "test.era")
        XCTAssertEqual(manifest.name, "Test Era")
        XCTAssertEqual(manifest.version, "2.0.0")
        XCTAssertEqual(manifest.author, "Community")
        XCTAssertEqual(manifest.eraPeriod, "1998-2000")
    }

    func testLayoutJSONDecoding() throws {
        let json = """
        {
          "defaultEdge": "top",
          "taskbarHeight": 32,
          "itemSpacing": 4,
          "paddingHorizontal": 4,
          "paddingVertical": 2,
          "startButtonWidth": 60,
          "taskButtonMinWidth": 50,
          "taskButtonMaxWidth": 180,
          "trayPadding": 6
        }
        """.data(using: .utf8)!

        let layout = try JSONDecoder().decode(EraLayoutConfig.self, from: json)
        XCTAssertEqual(layout.defaultEdge, .top)
        XCTAssertEqual(layout.taskbarHeight, 32)
        XCTAssertEqual(layout.itemSpacing, 4)
        XCTAssertEqual(layout.startButtonWidth, 60)
    }

    func testThemeColorHexParsing() {
        let theme = EraVisualTheme(
            backgroundColorHex: "#C0C0C0",
            surfaceColorHex: "#000080"
        )
        XCTAssertNotNil(theme.backgroundColor)
        XCTAssertNotNil(theme.surfaceColor)

        // Test custom hex initializer
        let red = NSColor(hex: "#FF0000")
        XCTAssertNotNil(red)

        let invalid = NSColor(hex: "not-a-color")
        XCTAssertNil(invalid)
    }

    func testProceduralIconsAvailable() {
        let start = ProceduralIcons.shared.startEmblem(size: 16)
        XCTAssertEqual(start.size.width, 16)
        XCTAssertEqual(start.size.height, 16)

        let prog = ProceduralIcons.shared.programsIcon(size: 20)
        XCTAssertEqual(prog.size.width, 20)

        let sound = ProceduralIcons.shared.soundIcon(size: 14)
        XCTAssertEqual(sound.size.width, 14)
    }
}
