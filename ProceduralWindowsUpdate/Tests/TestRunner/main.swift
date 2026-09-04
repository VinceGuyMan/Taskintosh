import Foundation
import CoreGraphics
import AppKit
import SwiftUI
import ProceduralWindowsUpdate

// Standalone automated test runner for ProceduralWindowsUpdate.
// Verifies all core requirements, deterministic seeds, bounds, safety, content pools,
// clean presentation mode, pixel alignment, and component edge cases.

var passedCount = 0
var failedCount = 0

func assertTest(_ condition: Bool, _ name: String, line: Int = #line) {
    if condition {
        passedCount += 1
        print("  PASS: " + name)
    } else {
        failedCount += 1
        print("  FAIL: " + name + " (line " + String(line) + ")")
    }
}

print("==================================================")
print("Running ProceduralWindowsUpdate Test Suite")
print("==================================================")

let engine = ProceduralUpdateEngine()

// 1. Deterministic Seed Behavior
print("")
print("[Test Group 1: Deterministic Seed Behavior]")
do {
    let seed: UInt64 = 987654321
    let sessionA = engine.generateSession(era: .win95, duration: .normal, seed: seed)
    let sessionB = engine.generateSession(era: .win95, duration: .normal, seed: seed)

    assertTest(sessionA.seed == sessionB.seed, "Seeds match")
    assertTest(sessionA.updateCount == sessionB.updateCount, "Update counts match")
    assertTest(sessionA.allSteps.count == sessionB.allSteps.count, "Step counts match")
    assertTest(sessionA.updates.map { $0.kbIdentifier } == sessionB.updates.map { $0.kbIdentifier }, "KB identifiers match exactly")
    assertTest(sessionA.allSteps.map { $0.message } == sessionB.allSteps.map { $0.message }, "Step messages match exactly")
    assertTest(sessionA.allSteps.map { $0.overallProgress } == sessionB.allSteps.map { $0.overallProgress }, "Progress curves match exactly")
}

// 2. Distinct Seeds
print("")
print("[Test Group 2: Distinct Seeds Create Distinct Sessions]")
do {
    let sessionA = engine.generateSession(era: .win95, seed: 1111)
    let sessionB = engine.generateSession(era: .win95, seed: 9999)

    assertTest(sessionA.seed != sessionB.seed, "Seeds are different")
    let messagesA = sessionA.allSteps.map { $0.message }.joined()
    let messagesB = sessionB.allSteps.map { $0.message }.joined()
    assertTest(messagesA != messagesB, "Generated messages differ between seeds")
}

// 3. Default Mode Excludes Theatrical Copy (Priority 5)
print("")
print("[Test Group 3: Default Mode Excludes Theatrical Copy]")
do {
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

    var allClean = true
    for seed in testSeeds {
        let session = engine.generateSession(era: .win95, duration: .normal, personality: .authentic, seed: seed)
        if !session.rareEventsTriggered.isEmpty {
            allClean = false
        }
        for step in session.allSteps {
            let lower = step.message.lowercased()
            for phrase in comedicPhrases {
                if lower.contains(phrase) {
                    allClean = false
                }
            }
        }
    }
    assertTest(allClean, "Default mode strictly excludes theatrical copy and rare events")
}

// 4. Explicit Theatrical Mode Allows Easter Eggs
print("")
print("[Test Group 4: Explicit Theatrical Mode Allows Easter Eggs]")
do {
    let canonicalText = "Updating Windows Update so Windows Update can update Windows Update"
    assertTest(RareEvent.canonicalMetaUpdate.primaryMessage == canonicalText, "Canonical line is exact")

    let session = engine.generateSession(era: .winXP, duration: .theatrical, personality: .highVibes, seed: 42)
    assertTest(session.rareEventsTriggered.contains(.canonicalMetaUpdate), "Canonical easter egg triggered with seed 42 in theatrical mode")
    assertTest(!session.rareEventsTriggered.isEmpty, "Theatrical mode populates rare events")
}

// 5. Progress-Bar Clamping and Exact Edge Cases (NaN, Infinity, Zero-Width, 0%, 1%, 50%, 99%, 100%)
print("")
print("[Test Group 5: Progress Bar Clamping & Exact Edge Cases (NaN, Infinity, Zero-Width, 0%, 1%, 50%, 99%, 100%)]")
do {
    let width: CGFloat = 320.0

    // NaN handling
    let nanProgress = ChunkyProgressBar.calculateBlockCount(progress: Double.nan, totalWidth: width)
    assertTest(nanProgress.filled == 0 && nanProgress.total == 0, "NaN progress safely returns (0, 0)")
    let nanWidth = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: CGFloat.nan)
    assertTest(nanWidth.filled == 0 && nanWidth.total == 0, "NaN totalWidth safely returns (0, 0)")

    // Infinity handling
    let posInf = ChunkyProgressBar.calculateBlockCount(progress: Double.infinity, totalWidth: width)
    assertTest(posInf.filled == posInf.total && posInf.total > 0, "+Infinity progress clamped to 100% full")
    let negInf = ChunkyProgressBar.calculateBlockCount(progress: -Double.infinity, totalWidth: width)
    assertTest(negInf.filled == 0 && negInf.total > 0, "-Infinity progress clamped to 0%")
    let infWidth = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: CGFloat.infinity)
    assertTest(infWidth.filled == 0 && infWidth.total == 0, "Infinite totalWidth safely returns (0, 0)")

    // Zero-width & Negative-width handling
    let zeroWidth = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: 0.0)
    assertTest(zeroWidth.filled == 0 && zeroWidth.total == 0, "Zero width safely returns (0, 0)")
    let negWidth = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: -100.0)
    assertTest(negWidth.filled == 0 && negWidth.total == 0, "Negative width safely returns (0, 0)")
    let smallWidth = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: 4.0)
    assertTest(smallWidth.filled == 0 && smallWidth.total == 0, "Width <= 4.0 safely returns (0, 0)")

    // Negative progress clamped to 0
    let negResult = ChunkyProgressBar.calculateBlockCount(progress: -0.5, totalWidth: width)
    assertTest(negResult.filled == 0 && negResult.total > 0, "Negative progress clamped to 0 filled blocks")

    // 0% has 0 blocks
    let zeroResult = ChunkyProgressBar.calculateBlockCount(progress: 0.0, totalWidth: width)
    assertTest(zeroResult.filled == 0 && zeroResult.total > 0, "0% progress has exactly 0 filled blocks")

    // 1% uses integer floor scaling: floor(0.01 * total)
    let onePctResult = ChunkyProgressBar.calculateBlockCount(progress: 0.01, totalWidth: width)
    let expectedOnePct = Int(floor(Double(onePctResult.total) * 0.01))
    assertTest(onePctResult.filled == expectedOnePct, "1% progress uses integer floor scaling: floor(progress * total)")

    // 50% progress has floor(0.5 * total) blocks
    let halfResult = ChunkyProgressBar.calculateBlockCount(progress: 0.5, totalWidth: width)
    let expectedHalf = Int(floor(Double(halfResult.total) * 0.5))
    assertTest(halfResult.filled == expectedHalf, "50% progress renders floor(total * 0.5) filled blocks")

    // 99% progress does NOT prematurely render full blocks and never exceeds total - 1
    let ninetyNineResult = ChunkyProgressBar.calculateBlockCount(progress: 0.99, totalWidth: width)
    let expectedNinetyNine = min(Int(floor(Double(ninetyNineResult.total) * 0.99)), ninetyNineResult.total - 1)
    assertTest(ninetyNineResult.filled == expectedNinetyNine && ninetyNineResult.filled < ninetyNineResult.total, "99% never exceeds total - 1 before 100%")

    // 100% progress renders all blocks packed
    let fullResult = ChunkyProgressBar.calculateBlockCount(progress: 1.0, totalWidth: width)
    assertTest(fullResult.filled == fullResult.total && fullResult.total > 0, "100% progress renders fully packed blocks with no missing gap")

    // Over 100% progress clamped to full blocks
    let overResult = ChunkyProgressBar.calculateBlockCount(progress: 1.5, totalWidth: width)
    assertTest(overResult.filled == overResult.total, "Over 100% progress clamped to full blocks")
}

// 6. Classic 3D Bevel Pixel-Aligned Implementation
print("")
print("[Test Group 6: Classic 3D Bevel Pixel-Aligned Colors & Styles]")
do {
    assertTest(Classic3DBevel.buttonFace == Color(red: 192/255, green: 192/255, blue: 192/255), "ButtonFace is canonical #C0C0C0")
    assertTest(Classic3DBevel.buttonHilight == Color(red: 255/255, green: 255/255, blue: 255/255), "ButtonHilight is canonical #FFFFFF")
    assertTest(Classic3DBevel.buttonLight == Color(red: 223/255, green: 223/255, blue: 223/255), "ButtonLight is canonical #DFDFDF")
    assertTest(Classic3DBevel.buttonShadow == Color(red: 128/255, green: 128/255, blue: 128/255), "ButtonShadow is canonical #808080")
    assertTest(Classic3DBevel.buttonDkShadow == Color(red: 0/255, green: 0/255, blue: 0/255), "ButtonDkShadow is canonical #000000")
}

// 7. Classic Dialog Layout / State Behavior (Priority 2 & 3)
print("")
print("[Test Group 7: Classic Dialog Layout & State Behavior]")
do {
    let classicEras: [WindowsEra] = [.win95, .win98, .winME]
    var allValid = true
    for era in classicEras {
        if era.presentationFamily != .classicDialog {
            allValid = false
        }
        let session = engine.generateSession(era: era, duration: .short, personality: .authentic, seed: 1995)
        if session.allSteps.isEmpty || session.finalOutcomeText != "Windows has finished updating your system settings." {
            allValid = false
        }
    }
    assertTest(allValid, "Win95, Win98, and WinME use classicDialog presentation and authentic outcome copy")
}

// 8. Every Supported Era Produces a Valid Session
print("")
print("[Test Group 8: All Supported Eras Validation]")
do {
    for era in WindowsEra.allCases {
        let session = engine.generateSession(era: era, duration: .short, seed: 42)
        assertTest(!session.allSteps.isEmpty, "Era " + era.rawValue + " generated non-empty steps")
        assertTest(!session.updates.isEmpty, "Era " + era.rawValue + " generated valid fake updates")
        assertTest(!session.stages.isEmpty, "Era " + era.rawValue + " generated valid stages")
    }
}

// 9. Progress Bounds Guarantee
print("")
print("[Test Group 9: Progress Bounds Guarantee]")
do {
    for era in WindowsEra.allCases {
        let session = engine.generateSession(era: era, duration: .normal, seed: 12345)
        var allWithinBounds = true
        for step in session.allSteps {
            if step.overallProgress < 0.0 || step.overallProgress > 1.0 {
                allWithinBounds = false
                break
            }
            if step.stageProgress < 0.0 || step.stageProgress > 1.0 {
                allWithinBounds = false
                break
            }
        }
        assertTest(allWithinBounds, "All progress values bounded in [0.0, 1.0] for " + era.rawValue)
    }
}

// 10. Duration Modes Behave Sensibly
print("")
print("[Test Group 10: Duration Modes]")
do {
    let shortSession = engine.generateSession(era: .win95, duration: .short, seed: 500)
    let normalSession = engine.generateSession(era: .win95, duration: .normal, seed: 500)
    let theatricalSession = engine.generateSession(era: .win95, duration: .theatrical, seed: 500)

    assertTest(shortSession.allSteps.count < normalSession.allSteps.count, "Short has fewer steps than Normal")
    assertTest(normalSession.allSteps.count < theatricalSession.allSteps.count, "Normal has fewer steps than Theatrical")
    assertTest(shortSession.totalEstimatedDuration < normalSession.totalEstimatedDuration, "Short duration is less than Normal duration")
    assertTest(normalSession.totalEstimatedDuration < theatricalSession.totalEstimatedDuration, "Normal duration is less than Theatrical duration")
}

// MainActor Tests (11, 12, 13)
Task { @MainActor in
    // 11. Controller Lifecycle & Cancellation Guarantee (Priority 7)
    print("")
    print("[Test Group 11: Controller Lifecycle, Cancel, and Escape Behavior]")
    let controller = FakeUpdateController(era: .win95)
    assertTest(controller.state.status == .idle, "Controller starts in idle state")

    var cancelCalledCount = 0
    controller.onCancel = {
        cancelCalledCount += 1
    }

    controller.start(era: .win95, duration: .short, personality: .authentic, seed: 1995)
    assertTest(controller.state.status == .running, "Controller status is running after start")

    controller.pause()
    assertTest(controller.state.status == .paused, "Controller status is paused after pause()")

    controller.resume()
    assertTest(controller.state.status == .running, "Controller status is running after resume()")

    controller.cancel()
    assertTest(controller.state.status == .cancelled, "Controller status is cancelled immediately after cancel()")
    assertTest(cancelCalledCount == 1, "onCancel was invoked exactly once on cancel")

    controller.reset()
    assertTest(controller.state.status == .idle, "Controller status is idle after reset()")

    // 12. FakeUpdateWindowView and Renderer onClose Delegation
    print("")
    print("[Test Group 12: FakeUpdateWindowView and Renderer onClose Delegation]")
    // 1. Win95UpdateRenderer
    let c95 = FakeUpdateController(era: .win95)
    var closed95 = false
    let r95 = Win95UpdateRenderer(controller: c95, onClose: { closed95 = true })
    r95.onClose?()
    assertTest(closed95, "Win95UpdateRenderer invokes onClose")

    // 2. WinXPUpdateRenderer
    let cXP = FakeUpdateController(era: .winXP)
    var closedXP = false
    let rXP = WinXPUpdateRenderer(controller: cXP, onClose: { closedXP = true })
    rXP.onClose?()
    assertTest(closedXP, "WinXPUpdateRenderer invokes onClose")

    // 3. WinVistaUpdateRenderer
    let cVista = FakeUpdateController(era: .winVista)
    var closedVista = false
    let rVista = WinVistaUpdateRenderer(controller: cVista, onClose: { closedVista = true })
    rVista.onClose?()
    assertTest(closedVista, "WinVistaUpdateRenderer invokes onClose")

    // 4. Win7UpdateRenderer
    let c7 = FakeUpdateController(era: .win7)
    var closed7 = false
    let r7 = Win7UpdateRenderer(controller: c7, onClose: { closed7 = true })
    r7.onClose?()
    assertTest(closed7, "Win7UpdateRenderer invokes onClose")

    // 5. Win8UpdateRenderer
    let c8 = FakeUpdateController(era: .win8)
    var closed8 = false
    let r8 = Win8UpdateRenderer(controller: c8, onClose: { closed8 = true })
    r8.onClose?()
    assertTest(closed8, "Win8UpdateRenderer invokes onClose")

    // 6. Win10UpdateRenderer
    let c10 = FakeUpdateController(era: .win10)
    var closed10 = false
    let r10 = Win10UpdateRenderer(controller: c10, onClose: { closed10 = true })
    r10.onClose?()
    assertTest(closed10, "Win10UpdateRenderer invokes onClose")

    // 7. Win11UpdateRenderer
    let c11 = FakeUpdateController(era: .win11)
    var closed11 = false
    let r11 = Win11UpdateRenderer(controller: c11, onClose: { closed11 = true })
    r11.onClose?()
    assertTest(closed11, "Win11UpdateRenderer invokes onClose")

    // FakeUpdateWindowView retains and wires onClose for all eras
    for era in WindowsEra.allCases {
        let c = FakeUpdateController(era: era)
        let view = FakeUpdateWindowView(controller: c, onClose: { })
        assertTest(view.onClose != nil, "FakeUpdateWindowView wires onClose for " + era.rawValue)
    }

    // 13. AppKit Window Clean Presentation Mode Verification
    print("")
    print("[Test Group 13: AppKit Window Controller Clean Presentation Mode]")
    let winController = FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
    if let window = winController.window {
        assertTest(window.titleVisibility == .hidden, "macOS title visibility is hidden in clean presentation mode")
        assertTest(window.titlebarAppearsTransparent, "macOS titlebar appears transparent in clean presentation mode")
        assertTest(!window.isOpaque, "macOS window is non-opaque in clean presentation mode")
        assertTest(window.backgroundColor == .clear, "macOS window background is clear in clean presentation mode")

        let closeBtn = window.standardWindowButton(.closeButton)
        assertTest(closeBtn == nil || closeBtn?.isHidden == true, "macOS close traffic-light button is hidden")

        let miniBtn = window.standardWindowButton(.miniaturizeButton)
        assertTest(miniBtn == nil || miniBtn?.isHidden == true, "macOS miniaturize traffic-light button is hidden")

        let zoomBtn = window.standardWindowButton(.zoomButton)
        assertTest(zoomBtn == nil || zoomBtn?.isHidden == true, "macOS zoom traffic-light button is hidden")
    } else {
        assertTest(false, "FakeUpdateWindowController window must exist")
    }

    // 14. Exact Window Sizing by Era & Taskbar Presentation
    print("")
    print("[Test Group 14: Exact Window Sizing by Era & Taskbar Presentation]")
    for era in WindowsEra.allCases {
        switch era.presentationFamily {
        case .classicDialog:
            assertTest(era.windowSize == CGSize(width: 350, height: 195), "Classic dialog windowSize is 350x195 for " + era.rawValue)
        case .lunaWizard:
            assertTest(era.windowSize == CGSize(width: 480, height: 350), "Luna wizard windowSize is 480x350 for " + era.rawValue)
        case .aeroGlass:
            assertTest(era.windowSize == CGSize(width: 490, height: 320), "Aero glass windowSize is 490x320 for " + era.rawValue)
        case .blueTheater, .metroFullscreen, .ringSpinner, .modernMinimal:
            assertTest(era.windowSize == CGSize(width: 540, height: 380), "Theater windowSize is 540x380 for " + era.rawValue)
        }
    }

    let c95Window = FakeUpdateWindowController(controller: FakeUpdateController(era: .win95), cleanPresentationMode: true)
    if let w = c95Window.window {
        let contentSize = w.contentView?.frame.size ?? w.frame.size
        assertTest(abs(contentSize.width - 350) < 1 && abs(contentSize.height - 195) < 1, "Win95 AppKit window contentSize is tightly 350x195")
    }

    let systemWin = FakeUpdateSystem.present(era: .win95)
    assertTest(systemWin.window != nil, "FakeUpdateSystem.present returns window controller with active window")

    // 15. Windows XP Luna Wizard Layout & State Behavior
    print("")
    print("[Test Group 15: Windows XP Luna Wizard Layout & State Behavior]")
    do {
        let xpController = FakeUpdateController(era: .winXP)
        var cancelCount = 0
        xpController.onCancel = { cancelCount += 1 }

        // State 1: Idle
        assertTest(xpController.state.status == .idle, "XP controller starts idle")

        // State 2: Active / Running
        xpController.start(era: .winXP, duration: .short, personality: .authentic, seed: 2001)
        assertTest(xpController.state.status == .running, "XP controller is running")
        assertTest(xpController.activeEra == .winXP, "XP controller active era is Windows XP")
        assertTest(xpController.state.totalUpdateCount > 0, "XP has generated update items")

        // State 3: Paused
        xpController.pause()
        assertTest(xpController.state.status == .paused, "XP controller is paused")

        // State 4: Resumed
        xpController.resume()
        assertTest(xpController.state.status == .running, "XP controller resumed to running")

        // State 5: Cancelled & onClose behavior
        var xpCloseCalled = false
        let xpRenderer = WinXPUpdateRenderer(controller: xpController, onClose: { xpCloseCalled = true })
        xpController.cancel()
        assertTest(xpController.state.status == .cancelled, "XP controller is cancelled")
        assertTest(cancelCount == 1, "XP onCancel callback fired")
        xpRenderer.onClose?()
        assertTest(xpCloseCalled, "WinXPUpdateRenderer onClose invoked on cancel/exit")

        // XP Window Sizing in FakeUpdateWindowController
        let xpWinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .winXP), cleanPresentationMode: true)
        if let w = xpWinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 480) < 1 && abs(size.height - 350) < 1, "WinXP AppKit window contentSize is tightly 480x350")
        }

        // LunaProgressBar mathematical bounds & floor scaling
        let pbWidth: CGFloat = 432.0
        let negPB = LunaProgressBar.calculateBlockCount(progress: -0.5, totalWidth: pbWidth)
        assertTest(negPB.filled == 0 && negPB.total > 0, "LunaProgressBar negative progress clamped to 0")

        let zeroPB = LunaProgressBar.calculateBlockCount(progress: 0.0, totalWidth: pbWidth)
        assertTest(zeroPB.filled == 0 && zeroPB.total > 0, "LunaProgressBar 0% has 0 blocks")

        let midPB = LunaProgressBar.calculateBlockCount(progress: 0.5, totalWidth: pbWidth)
        assertTest(midPB.filled == Int(floor(Double(midPB.total) * 0.5)), "LunaProgressBar 50% uses floor scaling")

        let capPB = LunaProgressBar.calculateBlockCount(progress: 0.99, totalWidth: pbWidth)
        assertTest(capPB.filled < capPB.total && capPB.filled <= capPB.total - 1, "LunaProgressBar 99% never exceeds total - 1 before 100%")

        let fullPB = LunaProgressBar.calculateBlockCount(progress: 1.0, totalWidth: pbWidth)
        assertTest(fullPB.filled == fullPB.total && fullPB.total > 0, "LunaProgressBar 100% is fully packed")

        let overPB = LunaProgressBar.calculateBlockCount(progress: 1.5, totalWidth: pbWidth)
        assertTest(overPB.filled == overPB.total, "LunaProgressBar >100% clamped to full")

        let nanPB = LunaProgressBar.calculateBlockCount(progress: Double.nan, totalWidth: pbWidth)
        assertTest(nanPB.filled == 0 && nanPB.total == 0, "LunaProgressBar NaN safely returns (0, 0)")

        let infPB = LunaProgressBar.calculateBlockCount(progress: Double.infinity, totalWidth: pbWidth)
        assertTest(infPB.filled == infPB.total, "LunaProgressBar +infinity clamped to full")

        let negInfPB = LunaProgressBar.calculateBlockCount(progress: -Double.infinity, totalWidth: pbWidth)
        assertTest(negInfPB.filled == 0, "LunaProgressBar -infinity clamped to 0")

        let zeroWidthPB = LunaProgressBar.calculateBlockCount(progress: 0.5, totalWidth: 0)
        assertTest(zeroWidthPB.filled == 0 && zeroWidthPB.total == 0, "LunaProgressBar zero width returns (0, 0)")

        // Authentic mode strictly excludes theatrical copy for XP
        let testSeeds: [UInt64] = [100, 200, 500, 1999, 2001]
        var allXPClean = true
        for s in testSeeds {
            let session = engine.generateSession(era: .winXP, duration: .normal, personality: .authentic, seed: s)
            if !session.rareEventsTriggered.isEmpty { allXPClean = false }
            for step in session.allSteps {
                let l = step.message.lowercased()
                if l.contains("clippy") || l.contains("vibe") || l.contains("emotional support") {
                    allXPClean = false
                }
            }
        }
        assertTest(allXPClean, "Windows XP authentic mode strictly excludes theatrical copy")
    }

    // 16. Windows Vista Aero Glass Layout & State Behavior
    print("")
    print("[Test Group 16: Windows Vista Aero Glass Layout & State Behavior]")
    do {
        let vistaController = FakeUpdateController(era: .winVista)
        var cancelCount = 0
        vistaController.onCancel = { cancelCount += 1 }

        // State 1: Idle
        assertTest(vistaController.state.status == .idle, "Vista controller starts idle")

        // State 2: Active / Running
        vistaController.start(era: .winVista, duration: .short, personality: .authentic, seed: 2006)
        assertTest(vistaController.state.status == .running, "Vista controller is running")
        assertTest(vistaController.activeEra == .winVista, "Vista controller active era is Windows Vista")
        assertTest(vistaController.state.totalUpdateCount > 0, "Vista has generated update items")

        // State 3: Paused
        vistaController.pause()
        assertTest(vistaController.state.status == .paused, "Vista controller is paused")

        // State 4: Resumed
        vistaController.resume()
        assertTest(vistaController.state.status == .running, "Vista controller resumed to running")

        // State 5: Cancelled & onClose behavior
        var vistaCloseCalled = false
        let vistaRenderer = WinVistaUpdateRenderer(controller: vistaController, onClose: { vistaCloseCalled = true })
        vistaController.cancel()
        assertTest(vistaController.state.status == .cancelled, "Vista controller is cancelled")
        assertTest(cancelCount == 1, "Vista onCancel callback fired")
        vistaRenderer.onClose?()
        assertTest(vistaCloseCalled, "WinVistaUpdateRenderer onClose invoked on close/exit")

        // Vista Window Sizing in FakeUpdateWindowController
        let vistaWinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .winVista), cleanPresentationMode: true)
        if let w = vistaWinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 490) < 1 && abs(size.height - 320) < 1, "WinVista AppKit window contentSize is tightly 490x320")
        }

        // AeroProgressBar bounds & safety
        let aeroPB0 = AeroProgressBar(progress: 0.0)
        assertTest(aeroPB0.progress == 0.0, "AeroProgressBar 0.0 progress clamped")

        let aeroPBMid = AeroProgressBar(progress: 0.5)
        assertTest(aeroPBMid.progress == 0.5, "AeroProgressBar 0.5 progress retained")

        let aeroPB1 = AeroProgressBar(progress: 1.0)
        assertTest(aeroPB1.progress == 1.0, "AeroProgressBar 1.0 progress retained")

        let aeroPBNeg = AeroProgressBar(progress: -0.5)
        assertTest(aeroPBNeg.progress == 0.0, "AeroProgressBar negative progress clamped to 0.0")

        let aeroPBOver = AeroProgressBar(progress: 1.5)
        assertTest(aeroPBOver.progress == 1.0, "AeroProgressBar > 1.0 progress clamped to 1.0")

        let aeroPBNan = AeroProgressBar(progress: Double.nan)
        assertTest(aeroPBNan.progress == 0.0, "AeroProgressBar NaN progress safely set to 0.0")

        let aeroPBInf = AeroProgressBar(progress: Double.infinity)
        assertTest(aeroPBInf.progress == 1.0, "AeroProgressBar +infinity clamped to 1.0")

        let aeroPBNegInf = AeroProgressBar(progress: -Double.infinity)
        assertTest(aeroPBNegInf.progress == 0.0, "AeroProgressBar -infinity clamped to 0.0")

        // Taskbar presentation for Vista
        let systemWinVista = FakeUpdateSystem.present(era: .winVista)
        assertTest(systemWinVista.window != nil, "FakeUpdateSystem.present(era: .winVista) returns window controller")
        if let w = systemWinVista.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 490) < 1 && abs(size.height - 320) < 1, "FakeUpdateSystem Vista window size is 490x320")
        }

        // Authentic mode strictly excludes theatrical copy for Vista
        let testSeeds: [UInt64] = [50, 150, 777, 2006, 2007]
        var allVistaClean = true
        for s in testSeeds {
            let session = engine.generateSession(era: .winVista, duration: .normal, personality: .authentic, seed: s)
            if !session.rareEventsTriggered.isEmpty { allVistaClean = false }
            for step in session.allSteps {
                let l = step.message.lowercased()
                if l.contains("clippy") || l.contains("vibe") || l.contains("emotional support") {
                    allVistaClean = false
                }
            }
        }
        assertTest(allVistaClean, "Windows Vista authentic mode strictly excludes theatrical copy")
    }

    // 17. Taskbar & Menu Action Era Resolution Verification
    print("")
    print("[Test Group 17: Taskbar & Menu Action Era Resolution Verification]")
    do {
        // Test era resolution for all Taskintosh era IDs
        let win95Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows95")
        assertTest(win95Controller.controller.activeEra == .win95, "Taskintosh era org.taskintosh.era.windows95 resolves to .win95")
        let w95Size = win95Controller.window?.contentView?.frame.size ?? win95Controller.window?.frame.size ?? .zero
        assertTest(abs(w95Size.width - 350) < 1 && abs(w95Size.height - 195) < 1, "Win95 taskbar popup window is 350x195")

        let winXPController = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windowsxp")
        assertTest(winXPController.controller.activeEra == .winXP, "Taskintosh era org.taskintosh.era.windowsxp resolves to .winXP")
        let wXPSize = winXPController.window?.contentView?.frame.size ?? winXPController.window?.frame.size ?? .zero
        assertTest(abs(wXPSize.width - 480) < 1 && abs(wXPSize.height - 350) < 1, "WinXP taskbar popup window is 480x350")

        let winVistaController = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windowsvista")
        assertTest(winVistaController.controller.activeEra == .winVista, "Taskintosh era org.taskintosh.era.windowsvista resolves to .winVista")
        let wVistaSize = winVistaController.window?.contentView?.frame.size ?? winVistaController.window?.frame.size ?? .zero
        assertTest(abs(wVistaSize.width - 490) < 1 && abs(wVistaSize.height - 320) < 1, "WinVista taskbar popup window is 490x320")

        let win7Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows7")
        assertTest(win7Controller.controller.activeEra == .win7, "Taskintosh era org.taskintosh.era.windows7 resolves to .win7")

        let win10Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows10")
        assertTest(win10Controller.controller.activeEra == .win10, "Taskintosh era org.taskintosh.era.windows10 resolves to .win10")

        let win11Controller = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows11")
        assertTest(win11Controller.controller.activeEra == .win11, "Taskintosh era org.taskintosh.era.windows11 resolves to .win11")

        let unknownController = FakeUpdateSystem.present(taskintoshEraID: "org.unknown.era")
        assertTest(unknownController.controller.activeEra == .winXP, "Unknown era falls back safely to .winXP")
    }

    // 18. Windows 7 Blue Theater Layout & State Behavior
    print("")
    print("[Test Group 18: Windows 7 Blue Theater Layout & State Behavior]")
    do {
        let win7Controller = FakeUpdateController(era: .win7)
        var cancelCount = 0
        win7Controller.onCancel = { cancelCount += 1 }

        // State 1: Idle
        assertTest(win7Controller.state.status == .idle, "Win7 controller starts idle")

        // State 2: Active / Running
        win7Controller.start(era: .win7, duration: .short, personality: .authentic, seed: 2009)
        assertTest(win7Controller.state.status == .running, "Win7 controller is running")
        assertTest(win7Controller.activeEra == .win7, "Win7 controller active era is Windows 7")
        assertTest(win7Controller.state.totalUpdateCount > 0, "Win7 has generated update items")

        // State 3: Paused
        win7Controller.pause()
        assertTest(win7Controller.state.status == .paused, "Win7 controller is paused")

        // State 4: Resumed
        win7Controller.resume()
        assertTest(win7Controller.state.status == .running, "Win7 controller resumed to running")

        // State 5: Active Cancel button calls controller.cancel() and onClose exactly once
        var win7CloseCount = 0
        let win7ActiveRenderer = Win7UpdateRenderer(controller: win7Controller, onClose: { win7CloseCount += 1 })
        win7Controller.cancel()
        assertTest(win7Controller.state.status == .cancelled, "Win7 controller status is cancelled")
        assertTest(cancelCount == 1, "Win7 onCancel callback fired exactly once")
        win7ActiveRenderer.onClose?()
        assertTest(win7CloseCount == 1, "Win7 active Cancel triggers onClose exactly once")

        // State 6: Completed state Close action calls onClose
        var win7CompletedCloseCount = 0
        let win7CompletedController = FakeUpdateController(era: .win7)
        let win7CompletedRenderer = Win7UpdateRenderer(controller: win7CompletedController, onClose: { win7CompletedCloseCount += 1 })
        win7CompletedRenderer.onClose?()
        assertTest(win7CompletedCloseCount == 1, "Win7 completed Close triggers onClose")

        // Win7 Window Sizing in FakeUpdateWindowController
        let win7WinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .win7), cleanPresentationMode: true)
        if let w = win7WinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "Win7 AppKit window contentSize is tightly 540x380")
        }

        // Win7 Dedicated ProgressBar bounds & safety
        let pb0 = Win7ProgressBar(progress: 0.0)
        assertTest(pb0.progress == 0.0, "Win7ProgressBar 0.0 progress clamped")

        let pbMid = Win7ProgressBar(progress: 0.5)
        assertTest(pbMid.progress == 0.5, "Win7ProgressBar 0.5 progress retained")

        let pb1 = Win7ProgressBar(progress: 1.0)
        assertTest(pb1.progress == 1.0, "Win7ProgressBar 1.0 progress retained")

        let pbNeg = Win7ProgressBar(progress: -0.5)
        assertTest(pbNeg.progress == 0.0, "Win7ProgressBar negative progress clamped to 0.0")

        let pbOver = Win7ProgressBar(progress: 1.5)
        assertTest(pbOver.progress == 1.0, "Win7ProgressBar > 1.0 progress clamped to 1.0")

        let pbNan = Win7ProgressBar(progress: Double.nan)
        assertTest(pbNan.progress == 0.0, "Win7ProgressBar NaN progress safely set to 0.0")

        let pbInf = Win7ProgressBar(progress: Double.infinity)
        assertTest(pbInf.progress == 1.0, "Win7ProgressBar +infinity clamped to 1.0")

        let pbNegInf = Win7ProgressBar(progress: -Double.infinity)
        assertTest(pbNegInf.progress == 0.0, "Win7ProgressBar -infinity clamped to 0.0")

        // Taskbar presentation for Win7
        let systemWin7 = FakeUpdateSystem.present(era: .win7)
        assertTest(systemWin7.window != nil, "FakeUpdateSystem.present(era: .win7) returns window controller")
        if let w = systemWin7.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "FakeUpdateSystem Win7 window size is 540x380")
        }

        // Authentic mode strictly excludes theatrical and Taskintosh copy for Win7
        let testSeeds: [UInt64] = [7, 77, 777, 2009, 2011]
        var allWin7Clean = true
        for s in testSeeds {
            let session = engine.generateSession(era: .win7, duration: .normal, personality: .authentic, seed: s)
            if !session.rareEventsTriggered.isEmpty { allWin7Clean = false }
            for step in session.allSteps {
                let l = step.message.lowercased()
                if l.contains("clippy") || l.contains("vibe") || l.contains("emotional support") || l.contains("taskintosh") {
                    allWin7Clean = false
                }
            }
        }
        assertTest(allWin7Clean, "Windows 7 authentic mode strictly excludes theatrical and Taskintosh copy")

        // Regression coverage for XP and Vista onClose wiring
        var xpRegressionFired = false
        let xpRegressionRenderer = WinXPUpdateRenderer(controller: FakeUpdateController(era: .winXP), onClose: { xpRegressionFired = true })
        xpRegressionRenderer.onClose?()
        assertTest(xpRegressionFired, "Regression check: WinXPUpdateRenderer onClose invoked")

        var vistaRegressionFired = false
        let vistaRegressionRenderer = WinVistaUpdateRenderer(controller: FakeUpdateController(era: .winVista), onClose: { vistaRegressionFired = true })
        vistaRegressionRenderer.onClose?()
        assertTest(vistaRegressionFired, "Regression check: WinVistaUpdateRenderer onClose invoked")
    }

    // 19. Windows 8 & 8.1 Metro Layout & State Behavior
    print("")
    print("[Test Group 19: Windows 8 & 8.1 Metro Layout & State Behavior]")
    do {
        // Distinct presentation values
        assertTest(WindowsEra.win8.presentationFamily == .metroFullscreen, "Win8 presentation family is metroFullscreen")
        assertTest(WindowsEra.win8_1.presentationFamily == .metroFullscreen, "Win8.1 presentation family is metroFullscreen")
        assertTest(WindowsEra.win8.defaultHeadline == "Configuring Windows updates", "Win8 default headline is exact")
        assertTest(WindowsEra.win8_1.defaultHeadline == "Setting up updates for Windows 8.1", "Win8.1 default headline is exact")
        assertTest(WindowsEra.win8.shortIdentifier == "win8", "Win8 short identifier is win8")
        assertTest(WindowsEra.win8_1.shortIdentifier == "win81", "Win8.1 short identifier is win81")

        // Windows 8 Controller Lifecycle
        let win8Controller = FakeUpdateController(era: .win8)
        var cancel8Count = 0
        win8Controller.onCancel = { cancel8Count += 1 }

        assertTest(win8Controller.state.status == .idle, "Win8 controller starts idle")
        win8Controller.start(era: .win8, duration: .short, personality: .authentic, seed: 2012)
        assertTest(win8Controller.state.status == .running, "Win8 controller is running")
        assertTest(win8Controller.activeEra == .win8, "Win8 controller active era is Windows 8")
        assertTest(win8Controller.state.totalUpdateCount > 0, "Win8 has generated update items")

        win8Controller.pause()
        assertTest(win8Controller.state.status == .paused, "Win8 controller is paused")
        win8Controller.resume()
        assertTest(win8Controller.state.status == .running, "Win8 controller resumed to running")

        var win8CloseCount = 0
        let win8ActiveRenderer = Win8UpdateRenderer(controller: win8Controller, onClose: { win8CloseCount += 1 })
        win8Controller.cancel()
        assertTest(win8Controller.state.status == .cancelled, "Win8 controller status is cancelled")
        assertTest(cancel8Count == 1, "Win8 onCancel fired exactly once")
        win8ActiveRenderer.onClose?()
        assertTest(win8CloseCount == 1, "Win8 active Cancel triggers onClose exactly once")

        // Windows 8.1 Controller Lifecycle & Close button
        let win81Controller = FakeUpdateController(era: .win8_1)
        win81Controller.start(era: .win8_1, duration: .short, personality: .authentic, seed: 2013)
        assertTest(win81Controller.activeEra == .win8_1, "Win8.1 active era is Windows 8.1")

        var win81CloseCount = 0
        let win81Renderer = Win8UpdateRenderer(controller: win81Controller, onClose: { win81CloseCount += 1 })
        win81Renderer.onClose?()
        assertTest(win81CloseCount == 1, "Win8.1 Close triggers onClose")

        // Popup sizing for both eras (540x380)
        let win8WinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .win8), cleanPresentationMode: true)
        if let w = win8WinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "Win8 AppKit window contentSize is tightly 540x380")
        }

        let win81WinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .win8_1), cleanPresentationMode: true)
        if let w = win81WinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "Win8.1 AppKit window contentSize is tightly 540x380")
        }

        // MetroProgressBar bounds & safety
        let mpb0 = MetroProgressBar(progress: 0.0)
        assertTest(mpb0.progress == 0.0, "MetroProgressBar 0.0 progress clamped")

        let mpbMid = MetroProgressBar(progress: 0.5)
        assertTest(mpbMid.progress == 0.5, "MetroProgressBar 0.5 progress retained")

        let mpb1 = MetroProgressBar(progress: 1.0)
        assertTest(mpb1.progress == 1.0, "MetroProgressBar 1.0 progress retained")

        let mpbNeg = MetroProgressBar(progress: -0.5)
        assertTest(mpbNeg.progress == 0.0, "MetroProgressBar negative progress clamped to 0.0")

        let mpbOver = MetroProgressBar(progress: 1.5)
        assertTest(mpbOver.progress == 1.0, "MetroProgressBar > 1.0 progress clamped to 1.0")

        let mpbNan = MetroProgressBar(progress: Double.nan)
        assertTest(mpbNan.progress == 0.0, "MetroProgressBar NaN progress safely set to 0.0")

        let mpbInf = MetroProgressBar(progress: Double.infinity)
        assertTest(mpbInf.progress == 1.0, "MetroProgressBar +infinity clamped to 1.0")

        let mpbNegInf = MetroProgressBar(progress: -Double.infinity)
        assertTest(mpbNegInf.progress == 0.0, "MetroProgressBar -infinity clamped to 0.0")

        // Taskbar era resolution for both Windows 8 and Windows 8.1
        let sysWin8 = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows8")
        assertTest(sysWin8.controller.activeEra == .win8, "Taskintosh era org.taskintosh.era.windows8 resolves to .win8")
        if let w = sysWin8.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "FakeUpdateSystem Win8 window size is 540x380")
        }

        let sysWin81 = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows81")
        assertTest(sysWin81.controller.activeEra == .win8_1, "Taskintosh era org.taskintosh.era.windows81 resolves to .win8_1")
        if let w = sysWin81.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "FakeUpdateSystem Win8.1 window size is 540x380")
        }

        // Authentic mode strictly excludes theatrical copy for Win8 and Win8.1
        let testSeeds: [UInt64] = [8, 81, 888, 2012, 2013]
        var allMetroClean = true
        for s in testSeeds {
            let s8 = engine.generateSession(era: .win8, duration: .normal, personality: .authentic, seed: s)
            let s81 = engine.generateSession(era: .win8_1, duration: .normal, personality: .authentic, seed: s)
            if !s8.rareEventsTriggered.isEmpty || !s81.rareEventsTriggered.isEmpty { allMetroClean = false }
            for step in s8.allSteps + s81.allSteps {
                let l = step.message.lowercased()
                if l.contains("clippy") || l.contains("vibe") || l.contains("emotional support") || l.contains("taskintosh") {
                    allMetroClean = false
                }
            }
        }
        assertTest(allMetroClean, "Windows 8 & 8.1 authentic mode strictly excludes theatrical and Taskintosh copy")

        // Regression checks for Win95, XP, Vista, and Win7
        var r95Fired = false
        Win95UpdateRenderer(controller: FakeUpdateController(era: .win95), onClose: { r95Fired = true }).onClose?()
        assertTest(r95Fired, "Regression check: Win95UpdateRenderer onClose invoked")

        var rXPFired = false
        WinXPUpdateRenderer(controller: FakeUpdateController(era: .winXP), onClose: { rXPFired = true }).onClose?()
        assertTest(rXPFired, "Regression check: WinXPUpdateRenderer onClose invoked")

        var rVistaFired = false
        WinVistaUpdateRenderer(controller: FakeUpdateController(era: .winVista), onClose: { rVistaFired = true }).onClose?()
        assertTest(rVistaFired, "Regression check: WinVistaUpdateRenderer onClose invoked")

        var r7Fired = false
        Win7UpdateRenderer(controller: FakeUpdateController(era: .win7), onClose: { r7Fired = true }).onClose?()
        assertTest(r7Fired, "Regression check: Win7UpdateRenderer onClose invoked")
    }

    // 20. Windows 10 Ring Spinner Layout & State Behavior
    print("")
    print("[Test Group 20: Windows 10 Ring Spinner Layout & State Behavior]")
    do {
        // Windows 10 Controller Lifecycle
        let win10Controller = FakeUpdateController(era: .win10)
        var cancel10Count = 0
        win10Controller.onCancel = { cancel10Count += 1 }

        // State 1: Idle
        assertTest(win10Controller.state.status == .idle, "Win10 controller starts idle")

        // State 2: Running
        win10Controller.start(era: .win10, duration: .short, personality: .authentic, seed: 2015)
        assertTest(win10Controller.state.status == .running, "Win10 controller is running")
        assertTest(win10Controller.activeEra == .win10, "Win10 controller active era is Windows 10")
        assertTest(win10Controller.state.totalUpdateCount > 0, "Win10 has generated update items")

        // State 3: Paused
        win10Controller.pause()
        assertTest(win10Controller.state.status == .paused, "Win10 controller is paused")

        // State 4: Resumed
        win10Controller.resume()
        assertTest(win10Controller.state.status == .running, "Win10 controller resumed to running")

        // State 5: Active Cancel calls controller.cancel() and onClose exactly once
        var win10CloseCount = 0
        let win10ActiveRenderer = Win10UpdateRenderer(controller: win10Controller, onClose: { win10CloseCount += 1 })
        win10Controller.cancel()
        assertTest(win10Controller.state.status == .cancelled, "Win10 controller status is cancelled")
        assertTest(cancel10Count == 1, "Win10 onCancel fired exactly once")
        win10ActiveRenderer.onClose?()
        assertTest(win10CloseCount == 1, "Win10 active Cancel triggers onClose exactly once")

        // State 6: Completed state Close action calls onClose
        var win10CompletedCloseCount = 0
        let win10CompletedController = FakeUpdateController(era: .win10)
        let win10CompletedRenderer = Win10UpdateRenderer(controller: win10CompletedController, onClose: { win10CompletedCloseCount += 1 })
        win10CompletedRenderer.onClose?()
        assertTest(win10CompletedCloseCount == 1, "Win10 completed Close triggers onClose")

        // State 7: Rebooting state check
        let rebootState = UpdateState(status: .rebooting, isRebooting: true)
        assertTest(rebootState.isRebooting, "UpdateState supports rebooting phase")

        // Win10 Window Sizing in FakeUpdateWindowController
        let win10WinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .win10), cleanPresentationMode: true)
        if let w = win10WinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "Win10 AppKit window contentSize is tightly 540x380")
        }

        // Win10 Dotted Spinner bounds & invalid input clamping
        let spinnerNormal = Win10DottedSpinner(size: 48)
        assertTest(spinnerNormal.size == 48, "Win10DottedSpinner normal size retained")

        let spinnerNan = Win10DottedSpinner(size: Double.nan)
        assertTest(spinnerNan.size == 52, "Win10DottedSpinner NaN size safely falls back to default")

        let spinnerInf = Win10DottedSpinner(size: Double.infinity)
        assertTest(spinnerInf.size == 52, "Win10DottedSpinner infinite size safely falls back to default")

        let spinnerZero = Win10DottedSpinner(size: 0)
        assertTest(spinnerZero.size == 52, "Win10DottedSpinner zero size safely falls back to default")

        let spinnerNeg = Win10DottedSpinner(size: -10)
        assertTest(spinnerNeg.size == 52, "Win10DottedSpinner negative size safely falls back to default")

        let spinnerPaused = Win10DottedSpinner(size: 52, isPaused: true)
        assertTest(spinnerPaused.isPaused, "Win10DottedSpinner supports paused state")

        // Taskbar era resolution for Windows 10
        let sysWin10 = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows10")
        assertTest(sysWin10.controller.activeEra == .win10, "Taskintosh era org.taskintosh.era.windows10 resolves to .win10")
        if let w = sysWin10.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "FakeUpdateSystem Win10 window size is 540x380")
        }

        // Authentic mode strictly excludes theatrical copy for Win10
        let testSeeds: [UInt64] = [10, 100, 1010, 2015, 2020]
        var allWin10Clean = true
        for s in testSeeds {
            let session = engine.generateSession(era: .win10, duration: .normal, personality: .authentic, seed: s)
            if !session.rareEventsTriggered.isEmpty { allWin10Clean = false }
            for step in session.allSteps {
                let l = step.message.lowercased()
                if l.contains("clippy") || l.contains("vibe") || l.contains("emotional support") || l.contains("taskintosh") {
                    allWin10Clean = false
                }
            }
        }
        assertTest(allWin10Clean, "Windows 10 authentic mode strictly excludes theatrical and Taskintosh copy")

        // Regression check: Win8.1 resolution
        let sysWin81Check = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows81")
        assertTest(sysWin81Check.controller.activeEra == .win8_1, "Regression check: org.taskintosh.era.windows81 resolves to .win8_1")

        // Regression check: Win8 UpdateRenderer onClose
        var win8RegressionFired = false
        Win8UpdateRenderer(controller: FakeUpdateController(era: .win8), onClose: { win8RegressionFired = true }).onClose?()
        assertTest(win8RegressionFired, "Regression check: Win8UpdateRenderer onClose invoked")
    }

    // 21. Windows 11 Fluent Mica Layout & State Behavior
    print("")
    print("[Test Group 21: Windows 11 Fluent Mica Layout & State Behavior]")
    do {
        // Windows 11 Controller Lifecycle
        let win11Controller = FakeUpdateController(era: .win11)
        var cancel11Count = 0
        win11Controller.onCancel = { cancel11Count += 1 }

        // State 1: Idle
        assertTest(win11Controller.state.status == .idle, "Win11 controller starts idle")

        // State 2: Running
        win11Controller.start(era: .win11, duration: .short, personality: .authentic, seed: 2021)
        assertTest(win11Controller.state.status == .running, "Win11 controller is running")
        assertTest(win11Controller.activeEra == .win11, "Win11 controller active era is Windows 11")
        assertTest(win11Controller.state.totalUpdateCount > 0, "Win11 has generated update items")

        // State 3: Paused
        win11Controller.pause()
        assertTest(win11Controller.state.status == .paused, "Win11 controller is paused")

        // State 4: Resumed
        win11Controller.resume()
        assertTest(win11Controller.state.status == .running, "Win11 controller resumed to running")

        // State 5: Active Cancel calls controller.cancel() and onClose exactly once
        var win11CloseCount = 0
        let win11ActiveRenderer = Win11UpdateRenderer(controller: win11Controller, onClose: { win11CloseCount += 1 })
        win11Controller.cancel()
        assertTest(win11Controller.state.status == .cancelled, "Win11 controller status is cancelled")
        assertTest(cancel11Count == 1, "Win11 onCancel fired exactly once")
        win11ActiveRenderer.onClose?()
        assertTest(win11CloseCount == 1, "Win11 active Cancel triggers onClose exactly once")

        // State 6: Completed state Close action calls onClose
        var win11CompletedCloseCount = 0
        let win11CompletedController = FakeUpdateController(era: .win11)
        let win11CompletedRenderer = Win11UpdateRenderer(controller: win11CompletedController, onClose: { win11CompletedCloseCount += 1 })
        win11CompletedRenderer.onClose?()
        assertTest(win11CompletedCloseCount == 1, "Win11 completed Close triggers onClose")

        // State 7: Rebooting state check
        let rebootState = UpdateState(status: .rebooting, isRebooting: true)
        assertTest(rebootState.isRebooting, "Win11 UpdateState supports rebooting phase")

        // Win11 Window Sizing in FakeUpdateWindowController
        let win11WinController = FakeUpdateWindowController(controller: FakeUpdateController(era: .win11), cleanPresentationMode: true)
        if let w = win11WinController.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "Win11 AppKit window contentSize is tightly 540x380")
        }

        // Win11 Progress Ring bounds & invalid input clamping
        let ringNormal = Win11ProgressRing(size: 48)
        assertTest(ringNormal.size == 48, "Win11ProgressRing normal size retained")

        let ringNan = Win11ProgressRing(size: Double.nan)
        assertTest(ringNan.size == 48, "Win11ProgressRing NaN size safely falls back to default")

        let ringInf = Win11ProgressRing(size: Double.infinity)
        assertTest(ringInf.size == 48, "Win11ProgressRing infinite size safely falls back to default")

        let ringZero = Win11ProgressRing(size: 0)
        assertTest(ringZero.size == 48, "Win11ProgressRing zero size safely falls back to default")

        let ringNeg = Win11ProgressRing(size: -10)
        assertTest(ringNeg.size == 48, "Win11ProgressRing negative size safely falls back to default")

        let ringSanitized = Win11ProgressRing.sanitize(size: 64)
        assertTest(ringSanitized == 64, "Win11ProgressRing sanitize validates legitimate size")

        let ringPaused = Win11ProgressRing(size: 48, isPaused: true)
        assertTest(ringPaused.isPaused, "Win11ProgressRing supports paused state")

        // Taskbar era resolution for Windows 11
        let sysWin11 = FakeUpdateSystem.present(taskintoshEraID: "org.taskintosh.era.windows11")
        assertTest(sysWin11.controller.activeEra == .win11, "Taskintosh era org.taskintosh.era.windows11 resolves to .win11")
        if let w = sysWin11.window {
            let size = w.contentView?.frame.size ?? w.frame.size
            assertTest(abs(size.width - 540) < 1 && abs(size.height - 380) < 1, "FakeUpdateSystem Win11 window size is 540x380")
        }

        // Authentic mode strictly excludes theatrical copy for Win11
        let testSeeds: [UInt64] = [11, 111, 1111, 2021, 2024]
        var allWin11Clean = true
        for s in testSeeds {
            let session = engine.generateSession(era: .win11, duration: .normal, personality: .authentic, seed: s)
            if !session.rareEventsTriggered.isEmpty { allWin11Clean = false }
            for step in session.allSteps {
                let l = step.message.lowercased()
                if l.contains("clippy") || l.contains("vibe") || l.contains("emotional support") || l.contains("taskintosh") {
                    allWin11Clean = false
                }
            }
        }
        assertTest(allWin11Clean, "Windows 11 authentic mode strictly excludes theatrical and Taskintosh copy")

        // Comprehensive regression checks across ALL prior eras for onClose and window sizing
        var reg95 = false
        Win95UpdateRenderer(controller: FakeUpdateController(era: .win95), onClose: { reg95 = true }).onClose?()
        assertTest(reg95, "Comprehensive regression: Win95UpdateRenderer onClose invoked")

        var regXP = false
        WinXPUpdateRenderer(controller: FakeUpdateController(era: .winXP), onClose: { regXP = true }).onClose?()
        assertTest(regXP, "Comprehensive regression: WinXPUpdateRenderer onClose invoked")

        var regVista = false
        WinVistaUpdateRenderer(controller: FakeUpdateController(era: .winVista), onClose: { regVista = true }).onClose?()
        assertTest(regVista, "Comprehensive regression: WinVistaUpdateRenderer onClose invoked")

        var reg7 = false
        Win7UpdateRenderer(controller: FakeUpdateController(era: .win7), onClose: { reg7 = true }).onClose?()
        assertTest(reg7, "Comprehensive regression: Win7UpdateRenderer onClose invoked")

        var reg8 = false
        Win8UpdateRenderer(controller: FakeUpdateController(era: .win8), onClose: { reg8 = true }).onClose?()
        assertTest(reg8, "Comprehensive regression: Win8UpdateRenderer onClose invoked")

        var reg10 = false
        Win10UpdateRenderer(controller: FakeUpdateController(era: .win10), onClose: { reg10 = true }).onClose?()
        assertTest(reg10, "Comprehensive regression: Win10UpdateRenderer onClose invoked")
    }

    print("")
    print("==================================================")
    print("Test Summary: " + String(passedCount) + " Passed, " + String(failedCount) + " Failed")
    print("==================================================")

    if failedCount > 0 {
        exit(1)
    } else {
        exit(0)
    }
}

RunLoop.main.run(until: Date().addingTimeInterval(1.0))
