import XCTest
import CoreGraphics
import AppKit
import SwiftUI
@testable import ProceduralWindowsUpdate

final class ProceduralWindowsUpdateTests: XCTestCase {

    var engine: ProceduralUpdateEngine!

    override func setUp() {
        super.setUp()
        engine = ProceduralUpdateEngine()
    }

    // 1. Deterministic Output
    func testDeterministicSeed() {
        let seed: UInt64 = 999111
        let session1 = engine.generateSession(era: .win95, seed: seed)
        let session2 = engine.generateSession(era: .win95, seed: seed)

        XCTAssertEqual(session1.seed, session2.seed)
        XCTAssertEqual(session1.updateCount, session2.updateCount)
        XCTAssertEqual(session1.allSteps.count, session2.allSteps.count)
        XCTAssertEqual(session1.allSteps.map(\.message), session2.allSteps.map(\.message))
        XCTAssertEqual(session1.allSteps.map(\.overallProgress), session2.allSteps.map(\.overallProgress))
    }

    // 2. Distinct Seeds
    func testDistinctSeeds() {
        let session1 = engine.generateSession(era: .win95, seed: 100)
        let session2 = engine.generateSession(era: .win95, seed: 200)

        XCTAssertNotEqual(session1.seed, session2.seed)
        XCTAssertNotEqual(session1.allSteps.map(\.message), session2.allSteps.map(\.message))
    }

    // 3. Default Mode Excludes Theatrical Copy
    func testDefaultModeExcludesTheatricalCopy() {
        let testSeeds: [UInt64] = [42, 100, 777, 1995, 2024]
        let comedicPhrases = [
            "clippy",
            "vibe",
            "optimism",
            "definitely_not_temp",
            "dignity",
            "suspiciously helpful",
            "emotional support",
            "windows update so windows update"
        ]

        for seed in testSeeds {
            let session = engine.generateSession(era: .win95, duration: .normal, personality: .authentic, seed: seed)

            // Rare events MUST be completely empty in default authentic mode
            XCTAssertTrue(session.rareEventsTriggered.isEmpty, "Default authentic mode must not trigger rare events (seed \(seed))")

            // Messages should contain zero comedy/theatrical phrases
            for step in session.allSteps {
                let lower = step.message.lowercased()
                for phrase in comedicPhrases {
                    XCTAssertFalse(
                        lower.contains(phrase),
                        "Found comedic phrase '\(phrase)' in default authentic mode: \(step.message)"
                    )
                }
            }
        }
    }

    // 4. Explicit Theatrical Mode Allows Easter Eggs
    func testExplicitTheatricalModeAllowsEasterEggs() {
        let text = "Updating Windows Update so Windows Update can update Windows Update"
        XCTAssertEqual(RareEvent.canonicalMetaUpdate.primaryMessage, text)

        let session = engine.generateSession(era: .winXP, duration: .theatrical, personality: .highVibes, seed: 42)
        XCTAssertTrue(session.rareEventsTriggered.contains(.canonicalMetaUpdate))
        XCTAssertFalse(session.rareEventsTriggered.isEmpty)
    }

    // 5. Progress-Bar Clamping, NaN, Infinity, Zero-Width & Edge Cases
    func testProgressBarClampingAndEdgeCases() {
        let width: CGFloat = 320.0
        let blockWidth: CGFloat = 6.0
        let spacing: CGFloat = 2.0

        // NaN handling
        let nanResult = ChunkyProgressBar.calculateBlockCount(progress: Double.nan, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(nanResult.filled, 0)
        XCTAssertEqual(nanResult.total, 0)

        let nanWidthResult = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: CGFloat.nan, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(nanWidthResult.filled, 0)
        XCTAssertEqual(nanWidthResult.total, 0)

        // Infinity handling
        let posInfResult = ChunkyProgressBar.calculateBlockCount(progress: Double.infinity, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(posInfResult.filled, posInfResult.total)
        XCTAssertGreaterThan(posInfResult.total, 0)

        let negInfResult = ChunkyProgressBar.calculateBlockCount(progress: -Double.infinity, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(negInfResult.filled, 0)
        XCTAssertGreaterThan(negInfResult.total, 0)

        // Zero-width & Negative-width
        let zeroWidthResult = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: 0.0, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(zeroWidthResult.filled, 0)
        XCTAssertEqual(zeroWidthResult.total, 0)

        let negWidthResult = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: -10.0, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(negWidthResult.filled, 0)
        XCTAssertEqual(negWidthResult.total, 0)

        // Negative clamped to 0
        let negResult = ChunkyProgressBar.calculateBlockCount(progress: -0.5, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(negResult.filled, 0)
        XCTAssertGreaterThan(negResult.total, 0)

        // 0.0 has 0 blocks
        let zeroResult = ChunkyProgressBar.calculateBlockCount(progress: 0.0, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(zeroResult.filled, 0)
        XCTAssertGreaterThan(zeroResult.total, 0)

        // 1% uses floor scaling: floor(0.01 * total)
        let onePctResult = ChunkyProgressBar.calculateBlockCount(progress: 0.01, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        let expectedOnePct = Int(floor(Double(onePctResult.total) * 0.01))
        XCTAssertEqual(onePctResult.filled, expectedOnePct)

        // Mid progress (50%) has proportion: floor(0.5 * total)
        let midResult = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        let expectedMid = Int(floor(Double(midResult.total) * 0.5))
        XCTAssertEqual(midResult.filled, expectedMid)

        // 99% progress does not prematurely render full blocks
        let ninetyNineResult = ChunkyProgressBar.calculateBlockCount(progress: 0.99, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertLessThan(ninetyNineResult.filled, ninetyNineResult.total)

        // 1.0 has full blocks (completed state rendering)
        let fullResult = ChunkyProgressBar.calculateBlockCount(progress: 1.0, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(fullResult.filled, fullResult.total)

        // Over 1.0 clamped to full blocks
        let overResult = ChunkyProgressBar.calculateBlockCount(progress: 1.5, totalWidth: width, blockWidth: blockWidth, spacing: spacing)
        XCTAssertEqual(overResult.filled, overResult.total)
    }

    // 6. Classic Dialog Layout/State Behavior
    func testClassicDialogLayoutAndStateBehavior() {
        let classicEras: [WindowsEra] = [.win95, .win98, .winME]

        for era in classicEras {
            XCTAssertEqual(era.presentationFamily, .classicDialog)

            let session = engine.generateSession(era: era, duration: .short, personality: .authentic, seed: 1995)
            XCTAssertFalse(session.allSteps.isEmpty)
            XCTAssertEqual(session.allSteps.last?.overallProgress, 1.0)
            XCTAssertEqual(session.finalOutcomeText, "Windows has finished updating your system settings.")
        }
    }

    // 7. Cancel and Escape Behavior
    @MainActor
    func testCancelAndEscapeBehavior() {
        let controller = FakeUpdateController(era: .win95)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelCallbackCalled = false
        controller.onCancel = {
            cancelCallbackCalled = true
        }

        controller.start(era: .win95, duration: .short, personality: .authentic, seed: 1995)
        XCTAssertEqual(controller.state.status, .running)

        // Cancel simulation
        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelCallbackCalled)
        XCTAssertEqual(controller.state.currentMessage, "Simulation cancelled.")

        // Reset back to idle
        controller.reset()
        XCTAssertEqual(controller.state.status, .idle)
    }

    // 8. Clean Presentation Mode
    @MainActor
    func testCleanPresentationMode() {
        let controller = FakeUpdateController(era: .win95)
        let windowController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = windowController.window else {
            XCTFail("Window should exist")
            return
        }

        XCTAssertEqual(window.titleVisibility, .hidden)
        XCTAssertTrue(window.titlebarAppearsTransparent)
        XCTAssertFalse(window.isOpaque)
        XCTAssertEqual(window.backgroundColor, .clear)

        let closeBtn = window.standardWindowButton(.closeButton)
        XCTAssertTrue(closeBtn == nil || closeBtn?.isHidden == true)
        let miniBtn = window.standardWindowButton(.miniaturizeButton)
        XCTAssertTrue(miniBtn == nil || miniBtn?.isHidden == true)
        let zoomBtn = window.standardWindowButton(.zoomButton)
        XCTAssertTrue(zoomBtn == nil || zoomBtn?.isHidden == true)
    }

    // 9. onClose Delegation
    @MainActor
    func testOnCloseDelegation() {
        let controller = FakeUpdateController(era: .win95)
        var closed = false
        let view = FakeUpdateWindowView(controller: controller, onClose: { closed = true })
        XCTAssertNotNil(view.onClose)
    }

    // 10. Exact Window Sizing and Taskbar Presentation
    @MainActor
    func testExactWindowSizingAndTaskbarPresentation() {
        XCTAssertEqual(WindowsEra.win95.windowSize, CGSize(width: 350, height: 195))
        XCTAssertEqual(WindowsEra.winXP.windowSize, CGSize(width: 480, height: 350))
        XCTAssertEqual(WindowsEra.winVista.windowSize, CGSize(width: 490, height: 320))
        XCTAssertEqual(WindowsEra.win7.windowSize, CGSize(width: 540, height: 380))

        let c95Window = FakeUpdateWindowController(controller: FakeUpdateController(era: .win95), cleanPresentationMode: true)
        guard let window = c95Window.window else {
            XCTFail("Window must exist")
            return
        }
        let contentSize = window.contentRect(forFrameRect: window.frame).size
        XCTAssertEqual(contentSize.width, 350, accuracy: 1.0)
        XCTAssertEqual(contentSize.height, 195, accuracy: 1.0)

        let systemWin = FakeUpdateSystem.present(era: .win95)
        XCTAssertNotNil(systemWin.window)
    }

    // 11. Windows XP Luna Wizard Tests
    @MainActor
    func testWindowsXPLunaWizard() {
        let controller = FakeUpdateController(era: .winXP)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelFired = false
        controller.onCancel = { cancelFired = true }

        controller.start(era: .winXP, duration: .short, personality: .authentic, seed: 2001)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .winXP)

        controller.pause()
        XCTAssertEqual(controller.state.status, .paused)

        controller.resume()
        XCTAssertEqual(controller.state.status, .running)

        var closeFired = false
        let renderer = WinXPUpdateRenderer(controller: controller, onClose: { closeFired = true })
        XCTAssertNotNil(renderer.onClose)

        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelFired)

        renderer.onClose?()
        XCTAssertTrue(closeFired)

        // Progress bar bounds
        let pb = LunaProgressBar.calculateBlockCount(progress: 0.5, totalWidth: 432.0)
        XCTAssertEqual(pb.filled, Int(floor(Double(pb.total) * 0.5)))
        XCTAssertEqual(LunaProgressBar.calculateBlockCount(progress: 1.0, totalWidth: 432.0).filled, pb.total)
        XCTAssertEqual(LunaProgressBar.calculateBlockCount(progress: -0.5, totalWidth: 432.0).filled, 0)
        XCTAssertEqual(LunaProgressBar.calculateBlockCount(progress: .nan, totalWidth: 432.0).filled, 0)
    }

    // 12. Windows Vista Aero Glass Tests
    @MainActor
    func testWindowsVistaAero() {
        let controller = FakeUpdateController(era: .winVista)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelFired = false
        controller.onCancel = { cancelFired = true }

        controller.start(era: .winVista, duration: .short, personality: .authentic, seed: 2006)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .winVista)

        controller.pause()
        XCTAssertEqual(controller.state.status, .paused)

        controller.resume()
        XCTAssertEqual(controller.state.status, .running)

        var closeFired = false
        let renderer = WinVistaUpdateRenderer(controller: controller, onClose: { closeFired = true })
        XCTAssertNotNil(renderer.onClose)

        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelFired)

        renderer.onClose?()
        XCTAssertTrue(closeFired)

        let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = winController.window else {
            XCTFail("Window must exist")
            return
        }
        let size = window.contentView?.frame.size ?? window.frame.size
        XCTAssertEqual(size.width, 490, accuracy: 1.0)
        XCTAssertEqual(size.height, 320, accuracy: 1.0)

        // Progress bar bounds
        let pb = AeroProgressBar(progress: 0.5)
        XCTAssertEqual(pb.progress, 0.5)
        XCTAssertEqual(AeroProgressBar(progress: -1.0).progress, 0.0)
        XCTAssertEqual(AeroProgressBar(progress: 2.0).progress, 1.0)
        XCTAssertEqual(AeroProgressBar(progress: Double.nan).progress, 0.0)
    }

    // 13. Windows 7 Blue Theater Tests
    @MainActor
    func testWindows7BlueTheater() {
        let controller = FakeUpdateController(era: .win7)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelFired = false
        controller.onCancel = { cancelFired = true }

        controller.start(era: .win7, duration: .short, personality: .authentic, seed: 2009)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .win7)

        controller.pause()
        XCTAssertEqual(controller.state.status, .paused)

        controller.resume()
        XCTAssertEqual(controller.state.status, .running)

        var closeFired = false
        let renderer = Win7UpdateRenderer(controller: controller, onClose: { closeFired = true })
        XCTAssertNotNil(renderer.onClose)

        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelFired)

        renderer.onClose?()
        XCTAssertTrue(closeFired)

        let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = winController.window else {
            XCTFail("Window must exist")
            return
        }
        let size = window.contentView?.frame.size ?? window.frame.size
        XCTAssertEqual(size.width, 540, accuracy: 1.0)
        XCTAssertEqual(size.height, 380, accuracy: 1.0)

        // Progress bar bounds
        let pb7 = Win7ProgressBar(progress: 0.5)
        XCTAssertEqual(pb7.progress, 0.5)
        XCTAssertEqual(Win7ProgressBar(progress: -1.0).progress, 0.0)
        XCTAssertEqual(Win7ProgressBar(progress: 2.0).progress, 1.0)
        XCTAssertEqual(Win7ProgressBar(progress: Double.nan).progress, 0.0)
    }

    // 14. Windows 8 Metro Tests
    @MainActor
    func testWindows8Metro() {
        let controller = FakeUpdateController(era: .win8)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelFired = false
        controller.onCancel = { cancelFired = true }

        controller.start(era: .win8, duration: .short, personality: .authentic, seed: 2012)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .win8)

        controller.pause()
        XCTAssertEqual(controller.state.status, .paused)

        controller.resume()
        XCTAssertEqual(controller.state.status, .running)

        var closeFired = false
        let renderer = Win8UpdateRenderer(controller: controller, onClose: { closeFired = true })
        XCTAssertNotNil(renderer.onClose)

        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelFired)

        renderer.onClose?()
        XCTAssertTrue(closeFired)

        let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = winController.window else {
            XCTFail("Window must exist")
            return
        }
        let size = window.contentView?.frame.size ?? window.frame.size
        XCTAssertEqual(size.width, 540, accuracy: 1.0)
        XCTAssertEqual(size.height, 380, accuracy: 1.0)

        // Progress bar bounds
        let mpb = MetroProgressBar(progress: 0.5)
        XCTAssertEqual(mpb.progress, 0.5)
        XCTAssertEqual(MetroProgressBar(progress: -1.0).progress, 0.0)
        XCTAssertEqual(MetroProgressBar(progress: 2.0).progress, 1.0)
        XCTAssertEqual(MetroProgressBar(progress: Double.nan).progress, 0.0)
    }

    // 15. Windows 8.1 Metro Tests
    @MainActor
    func testWindows81Metro() {
        let controller = FakeUpdateController(era: .win8_1)
        XCTAssertEqual(controller.state.status, .idle)

        controller.start(era: .win8_1, duration: .short, personality: .authentic, seed: 2013)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .win8_1)

        var closeFired = false
        let renderer = Win8UpdateRenderer(controller: controller, onClose: { closeFired = true })
        renderer.onClose?()
        XCTAssertTrue(closeFired)

        let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = winController.window else {
            XCTFail("Window must exist")
            return
        }
        let size = window.contentView?.frame.size ?? window.frame.size
        XCTAssertEqual(size.width, 540, accuracy: 1.0)
        XCTAssertEqual(size.height, 380, accuracy: 1.0)
    }

    // 16. Windows 10 Ring Spinner Tests
    @MainActor
    func testWindows10RingSpinner() {
        let controller = FakeUpdateController(era: .win10)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelFired = false
        controller.onCancel = { cancelFired = true }

        controller.start(era: .win10, duration: .short, personality: .authentic, seed: 2015)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .win10)

        controller.pause()
        XCTAssertEqual(controller.state.status, .paused)

        controller.resume()
        XCTAssertEqual(controller.state.status, .running)

        var closeFired = false
        let renderer = Win10UpdateRenderer(controller: controller, onClose: { closeFired = true })
        XCTAssertNotNil(renderer.onClose)

        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelFired)

        renderer.onClose?()
        XCTAssertTrue(closeFired)

        let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = winController.window else {
            XCTFail("Window must exist")
            return
        }
        let size = window.contentView?.frame.size ?? window.frame.size
        XCTAssertEqual(size.width, 540, accuracy: 1.0)
        XCTAssertEqual(size.height, 380, accuracy: 1.0)

        // Spinner bounds and safety
        let spinnerNormal = Win10DottedSpinner(size: 48)
        XCTAssertEqual(spinnerNormal.size, 48)
        let spinnerNan = Win10DottedSpinner(size: Double.nan)
        XCTAssertEqual(spinnerNan.size, 52)
        let spinnerZero = Win10DottedSpinner(size: 0)
        XCTAssertEqual(spinnerZero.size, 52)
        let spinnerNeg = Win10DottedSpinner(size: -10)
        XCTAssertEqual(spinnerNeg.size, 52)
    }

    // 17. Windows 11 Fluent Mica Tests
    @MainActor
    func testWindows11FluentMica() {
        let controller = FakeUpdateController(era: .win11)
        XCTAssertEqual(controller.state.status, .idle)

        var cancelFired = false
        controller.onCancel = { cancelFired = true }

        controller.start(era: .win11, duration: .short, personality: .authentic, seed: 2021)
        XCTAssertEqual(controller.state.status, .running)
        XCTAssertEqual(controller.activeEra, .win11)

        controller.pause()
        XCTAssertEqual(controller.state.status, .paused)

        controller.resume()
        XCTAssertEqual(controller.state.status, .running)

        var closeFired = false
        let renderer = Win11UpdateRenderer(controller: controller, onClose: { closeFired = true })
        XCTAssertNotNil(renderer.onClose)

        controller.cancel()
        XCTAssertEqual(controller.state.status, .cancelled)
        XCTAssertTrue(cancelFired)

        renderer.onClose?()
        XCTAssertTrue(closeFired)

        let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        guard let window = winController.window else {
            XCTFail("Window must exist")
            return
        }
        let size = window.contentView?.frame.size ?? window.frame.size
        XCTAssertEqual(size.width, 540, accuracy: 1.0)
        XCTAssertEqual(size.height, 380, accuracy: 1.0)

        // Progress ring bounds and safety
        let ringNormal = Win11ProgressRing(size: 48)
        XCTAssertEqual(ringNormal.size, 48)
        let ringNan = Win11ProgressRing(size: Double.nan)
        XCTAssertEqual(ringNan.size, 48)
        let ringZero = Win11ProgressRing(size: 0)
        XCTAssertEqual(ringZero.size, 48)
        let ringNeg = Win11ProgressRing(size: -10)
        XCTAssertEqual(ringNeg.size, 48)
        XCTAssertEqual(Win11ProgressRing.sanitize(size: 64), 64)
    }
}
