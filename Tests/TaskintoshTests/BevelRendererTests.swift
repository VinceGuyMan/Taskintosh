import XCTest
import AppKit
@testable import TaskintoshKit

final class BevelRendererTests: XCTestCase {
    func testBevelRendererColors() {
        let theme = EraVisualTheme(
            lightHighlightColorHex: "#FFFFFF",
            shadowColorHex: "#808080",
            darkShadowColorHex: "#000000"
        )

        XCTAssertEqual(theme.lightHighlightColorHex, "#FFFFFF")
        XCTAssertEqual(theme.shadowColorHex, "#808080")
        XCTAssertEqual(theme.darkShadowColorHex, "#000000")
    }

    func testBevelRendererDoesNotCrashOnZeroRect() {
        let theme = EraVisualTheme()
        BevelRenderer.shared.drawRaisedBevel(in: .zero, theme: theme)
        BevelRenderer.shared.drawSunkenBevel(in: .zero, theme: theme)
        BevelRenderer.shared.drawEtchedBorder(in: .zero, theme: theme)
    }
}
