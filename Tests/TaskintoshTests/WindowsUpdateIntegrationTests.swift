import XCTest
import AppKit
@testable import TaskintoshKit
import ProceduralWindowsUpdate

final class WindowsUpdateIntegrationTests: XCTestCase {

    @MainActor
    func testWindowsUpdateEraResolutionAndPresentation() {
        // Verify taskbar integration maps active Taskintosh era to WindowsEra correctly
        let win95Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows95")
        XCTAssertEqual(win95Controller.controller.activeEra, .win95)
        let w95Size = win95Controller.window?.contentView?.frame.size ?? win95Controller.window?.frame.size ?? .zero
        XCTAssertEqual(w95Size.width, 350, accuracy: 1.0)
        XCTAssertEqual(w95Size.height, 195, accuracy: 1.0)

        let winXPController = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windowsxp")
        XCTAssertEqual(winXPController.controller.activeEra, .winXP)
        let wXPSize = winXPController.window?.contentView?.frame.size ?? winXPController.window?.frame.size ?? .zero
        XCTAssertEqual(wXPSize.width, 480, accuracy: 1.0)
        XCTAssertEqual(wXPSize.height, 350, accuracy: 1.0)

        let winVistaController = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windowsvista")
        XCTAssertEqual(winVistaController.controller.activeEra, .winVista)
        let wVistaSize = winVistaController.window?.contentView?.frame.size ?? winVistaController.window?.frame.size ?? .zero
        XCTAssertEqual(wVistaSize.width, 490, accuracy: 1.0)
        XCTAssertEqual(wVistaSize.height, 320, accuracy: 1.0)

        let win7Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows7")
        XCTAssertEqual(win7Controller.controller.activeEra, .win7)
        let w7Size = win7Controller.window?.contentView?.frame.size ?? win7Controller.window?.frame.size ?? .zero
        XCTAssertEqual(w7Size.width, 540, accuracy: 1.0)
        XCTAssertEqual(w7Size.height, 380, accuracy: 1.0)

        let win8Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows8")
        XCTAssertEqual(win8Controller.controller.activeEra, .win8)
        let w8Size = win8Controller.window?.contentView?.frame.size ?? win8Controller.window?.frame.size ?? .zero
        XCTAssertEqual(w8Size.width, 540, accuracy: 1.0)
        XCTAssertEqual(w8Size.height, 380, accuracy: 1.0)

        let win81Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows81")
        XCTAssertEqual(win81Controller.controller.activeEra, .win8_1)
        let w81Size = win81Controller.window?.contentView?.frame.size ?? win81Controller.window?.frame.size ?? .zero
        XCTAssertEqual(w81Size.width, 540, accuracy: 1.0)
        XCTAssertEqual(w81Size.height, 380, accuracy: 1.0)

        let win10Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows10")
        XCTAssertEqual(win10Controller.controller.activeEra, .win10)
        let w10Size = win10Controller.window?.contentView?.frame.size ?? win10Controller.window?.frame.size ?? .zero
        XCTAssertEqual(w10Size.width, 540, accuracy: 1.0)
        XCTAssertEqual(w10Size.height, 380, accuracy: 1.0)

        let win11Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows11")
        XCTAssertEqual(win11Controller.controller.activeEra, .win11)
        let w11Size = win11Controller.window?.contentView?.frame.size ?? win11Controller.window?.frame.size ?? .zero
        XCTAssertEqual(w11Size.width, 540, accuracy: 1.0)
        XCTAssertEqual(w11Size.height, 380, accuracy: 1.0)

        // Cancellation safety
        win8Controller.controller.cancel()
        XCTAssertEqual(win8Controller.controller.state.status, .cancelled)
        win81Controller.controller.cancel()
        XCTAssertEqual(win81Controller.controller.state.status, .cancelled)
        win10Controller.controller.cancel()
        XCTAssertEqual(win10Controller.controller.state.status, .cancelled)
        win11Controller.controller.cancel()
        XCTAssertEqual(win11Controller.controller.state.status, .cancelled)
    }
}
