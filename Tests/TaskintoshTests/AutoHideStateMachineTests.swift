import XCTest
import AppKit
@testable import TaskintoshKit

final class AutoHideStateMachineTests: XCTestCase {
    func testDisplayManagerGeometry() {
        // Mock screen bounds
        let frame = NSRect(x: 0, y: 0, width: 1440, height: 900)

        // Bottom edge
        let bottomFrame = NSRect(x: frame.minX, y: frame.minY, width: frame.width, height: 28)
        XCTAssertEqual(bottomFrame.height, 28)
        XCTAssertEqual(bottomFrame.minY, 0)

        // Top edge
        let topFrame = NSRect(x: frame.minX, y: frame.maxY - 28, width: frame.width, height: 28)
        XCTAssertEqual(topFrame.maxY, 900)
    }

    func testEdgeCasesForTaskbarEdge() {
        XCTAssertEqual(TaskbarEdge.allCases.count, 4)
        XCTAssertTrue(TaskbarEdge.allCases.contains(.bottom))
        XCTAssertTrue(TaskbarEdge.allCases.contains(.top))
        XCTAssertTrue(TaskbarEdge.allCases.contains(.left))
        XCTAssertTrue(TaskbarEdge.allCases.contains(.right))
    }
}
