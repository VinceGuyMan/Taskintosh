import XCTest
import AppKit
@testable import TaskintoshKit

final class TaskItemTests: XCTestCase {
    func testTaskItemEqualityAndHashing() {
        let item1 = TaskItem(
            id: "com.apple.Safari-1234",
            title: "Safari",
            icon: nil,
            pid: 1234,
            bundleIdentifier: "com.apple.Safari",
            isActive: true,
            isMinimized: false
        )

        let item2 = TaskItem(
            id: "com.apple.Safari-1234",
            title: "Safari",
            icon: nil,
            pid: 1234,
            bundleIdentifier: "com.apple.Safari",
            isActive: true,
            isMinimized: false
        )

        let item3 = TaskItem(
            id: "com.apple.Safari-1234",
            title: "Safari",
            icon: nil,
            pid: 1234,
            bundleIdentifier: "com.apple.Safari",
            isActive: false,
            isMinimized: false
        )

        XCTAssertEqual(item1, item2)
        XCTAssertNotEqual(item1, item3)

        var set = Set<TaskItem>()
        set.insert(item1)
        XCTAssertTrue(set.contains(item2))
    }
}
