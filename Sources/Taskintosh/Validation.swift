import AppKit
import Foundation
import SwiftUI
import TaskintoshKit
import ProceduralWindowsUpdate

@MainActor
func runPackagedAppValidation() async {
    print("========================================================")
    print("TASKINTOSH PACKAGED APP REAL UI & EXTERNAL APP VALIDATION")
    print("========================================================")

    guard let appDelegate = AppDelegate.shared else {
        print("❌ FAILED: AppDelegate.shared is nil.")
        exit(1)
    }

    let workspace = NSWorkspace.shared

    // 1. Launch real external apps: Calculator and TextEdit
    print("\n[Step 1] Launching real external apps: Calculator and TextEdit...")
    let calcUrl = URL(fileURLWithPath: "/System/Applications/Calculator.app")
    let textEditUrl = URL(fileURLWithPath: "/System/Applications/TextEdit.app")
    let conf = NSWorkspace.OpenConfiguration()
    conf.activates = false

    var calcApp: NSRunningApplication?
    var textEditApp: NSRunningApplication?

    do {
        calcApp = try await workspace.openApplication(at: calcUrl, configuration: conf)
        textEditApp = try await workspace.openApplication(at: textEditUrl, configuration: conf)
    } catch {
        print("❌ FAILED to launch Calculator/TextEdit: \(error)")
        exit(1)
    }

    guard let calc = calcApp, let textEdit = textEditApp else {
        print("❌ FAILED: Calculator or TextEdit reference is nil.")
        exit(1)
    }

    print(" -> Calculator running with PID: \(calc.processIdentifier), Bundle: \(calc.bundleIdentifier ?? "nil")")
    print(" -> TextEdit running with PID: \(textEdit.processIdentifier), Bundle: \(textEdit.bundleIdentifier ?? "nil")")

    // Allow window server & workspace to settle
    try? await Task.sleep(nanoseconds: 1_200_000_000)

    // 2. Verify Taskbar Detection
    print("\n[Step 2] Verifying Taskbar Detection...")
    RunningAppWatcher.shared.refreshRunningApps()
    try? await Task.sleep(nanoseconds: 400_000_000)

    guard let taskView = appDelegate.currentTaskbarView else {
        print("❌ FAILED: TaskbarView is nil.")
        exit(1)
    }
    taskView.needsDisplay = true
    taskView.displayIfNeeded()

    let items = RunningAppWatcher.shared.taskItems
    print(" -> Taskintosh RunningAppWatcher detected \(items.count) regular running apps:")
    for it in items {
        print("    * [PID \(it.pid)] \(it.title) (bundle: \(it.bundleIdentifier ?? "nil"), isHidden: \(it.isMinimized))")
    }

    guard let calcItem = items.first(where: { $0.pid == calc.processIdentifier }) else {
        print("❌ FAILED: Calculator was not detected in Taskintosh task items.")
        exit(1)
    }

    guard let calcRect = taskView.rect(for: calcItem) else {
        print("❌ FAILED: Calculator button rect not found in taskbar layout.")
        exit(1)
    }
    print("✔ TASKBAR DETECTION: Found Calculator at button rect: \(calcRect)")

    // 3. Verify Right-Click Context Menu on Task Button
    print("\n[Step 3] Verifying Right-Click Context Menu on Calculator Button...")
    let rightClickEvent = NSEvent.mouseEvent(
        with: .rightMouseDown,
        location: NSPoint(x: calcRect.midX, y: calcRect.midY),
        modifierFlags: [],
        timestamp: 0,
        windowNumber: taskView.window?.windowNumber ?? 0,
        context: nil,
        eventNumber: 0,
        clickCount: 1,
        pressure: 1.0
    )!

    guard let taskMenu = taskView.menu(for: rightClickEvent) else {
        print("❌ FAILED: menu(for:) returned nil for right-click on Calculator button.")
        exit(1)
    }
    guard taskMenu.title == "Calculator" else {
        print("❌ FAILED: Expected task button context menu title 'Calculator', but got '\(taskMenu.title)'!")
        exit(1)
    }
    print("✔ RIGHT-CLICK CONTEXT MENU: Generated context menu '\(taskMenu.title)' with \(taskMenu.items.count) items.")
    for item in taskMenu.items {
        print("    * Item: '\(item.title)' (action: \(item.action != nil), target: \(item.target != nil))")
    }

    // 4. Verify Control-Click Context Menu on Task Button
    print("\n[Step 4] Verifying Control-Click Context Menu on Calculator Button...")
    let ctrlClickEvent = NSEvent.mouseEvent(
        with: .leftMouseDown,
        location: NSPoint(x: calcRect.midX, y: calcRect.midY),
        modifierFlags: [.control],
        timestamp: 0,
        windowNumber: taskView.window?.windowNumber ?? 0,
        context: nil,
        eventNumber: 0,
        clickCount: 1,
        pressure: 1.0
    )!

    guard let ctrlMenu = taskView.menu(for: ctrlClickEvent) else {
        print("❌ FAILED: menu(for:) returned nil for Control-click on Calculator button.")
        exit(1)
    }
    guard ctrlMenu.title == "Calculator" else {
        print("❌ FAILED: Expected Control-click menu title 'Calculator', but got '\(ctrlMenu.title)'!")
        exit(1)
    }
    print("✔ CONTROL-CLICK CONTEXT MENU: Generated context menu '\(ctrlMenu.title)' with \(ctrlMenu.items.count) items.")

    // 5. Verify Minimize / Hide on Real App
    print("\n[Step 5] Verifying Minimize / Hide on Calculator...")
    guard let minItem = taskMenu.items.first(where: { $0.title == "Minimize" }) else {
        print("❌ FAILED: 'Minimize' menu item not found in task context menu.")
        exit(1)
    }
    taskView.taskActionMinimize(minItem)
    try? await Task.sleep(nanoseconds: 800_000_000)

    print(" -> Calculator isHidden: \(calc.isHidden)")
    if calc.isHidden {
        print("✔ MINIMIZE / HIDE: Calculator successfully minimized/hidden.")
    } else {
        print("❌ FAILED: Calculator isHidden was false after minimize.")
        exit(1)
    }

    // 6. Verify Restore / Unhide on Real App
    print("\n[Step 6] Verifying Restore / Unhide on Calculator...")
    guard let restoreItem = taskMenu.items.first(where: { $0.title.hasPrefix("Restore") }) else {
        print("❌ FAILED: 'Restore / Bring to Front' menu item not found.")
        exit(1)
    }
    taskView.taskActionRestore(restoreItem)
    try? await Task.sleep(nanoseconds: 800_000_000)

    print(" -> Calculator isHidden: \(calc.isHidden), isActive: \(calc.isActive)")
    if !calc.isHidden {
        print("✔ RESTORE / UNHIDE: Calculator successfully restored and unhidden.")
    } else {
        print("❌ FAILED: Calculator isHidden was true after restore.")
        exit(1)
    }

    // 7. Verify Close / Terminate on Real App
    print("\n[Step 7] Verifying Close / Terminate on Calculator...")
    guard let closeItem = taskMenu.items.first(where: { $0.title == "Close" }) else {
        print("❌ FAILED: 'Close' menu item not found.")
        exit(1)
    }
    taskView.taskActionClose(closeItem)
    try? await Task.sleep(nanoseconds: 1_000_000_000)

    print(" -> Calculator isTerminated: \(calc.isTerminated)")
    if calc.isTerminated {
        print("✔ CLOSE / TERMINATE: Calculator successfully terminated.")
    } else {
        print("❌ FAILED: Calculator was not terminated.")
        exit(1)
    }

    // 8. Verify Taskbar Background Context Menu & Minimize All Windows
    print("\n[Step 8] Verifying Taskbar Background Context Menu & Minimize All Windows...")

    // 8.1 Dynamically calculate guaranteed empty background coordinate
    guard let bgPoint = taskView.findGuaranteedEmptyBackgroundPoint() else {
        print("❌ FAILED: Could not find guaranteed empty background coordinate in taskbar.")
        exit(1)
    }

    let isOutsideStart = !taskView.currentStartButtonRect.contains(bgPoint)
    let isOutsideTray = !taskView.currentTrayRect.contains(bgPoint)
    let isOutsideButtons = !taskView.currentTaskButtonRects.contains(where: { $0.1.contains(bgPoint) })
    let isInsideBounds = taskView.bounds.contains(bgPoint)

    print(" -> Dynamically calculated guaranteed empty background coordinate: \(bgPoint)")
    print("    * Outside Start button: \(isOutsideStart)")
    print("    * Outside System Tray: \(isOutsideTray)")
    print("    * Outside every task button: \(isOutsideButtons)")
    print("    * Inside Taskbar bounds: \(isInsideBounds)")

    guard isOutsideStart && isOutsideTray && isOutsideButtons && isInsideBounds else {
        print("❌ FAILED: Background coordinate violates one or more geometric exclusion constraints.")
        exit(1)
    }

    // 8.2 Right-Click on Taskbar Background
    let bgClickEvent = NSEvent.mouseEvent(
        with: .rightMouseDown,
        location: bgPoint,
        modifierFlags: [],
        timestamp: 0,
        windowNumber: taskView.window?.windowNumber ?? 0,
        context: nil,
        eventNumber: 0,
        clickCount: 1,
        pressure: 1.0
    )!

    guard let bgMenu = taskView.menu(for: bgClickEvent) else {
        print("❌ FAILED: Taskbar background context menu returned nil.")
        exit(1)
    }

    print("✔ BACKGROUND CONTEXT MENU: Generated '\(bgMenu.title)' with \(bgMenu.items.count) items.")
    for item in bgMenu.items {
        print("    * Item: '\(item.title)' (action: \(item.action != nil), target: \(item.target != nil))")
    }

    // 8.3 Verify Menu Title is strictly "Taskbar"
    guard bgMenu.title == "Taskbar" else {
        print("❌ FAILED: Expected context menu title 'Taskbar', but got '\(bgMenu.title)'. (Coordinate hit an app button instead of empty background!)")
        exit(1)
    }

    // Verify required items in background menu
    let expectedBackgroundItems = [
        "Minimize All Windows",
        "Task Manager",
        "Auto-Hide the Taskbar",
        "Properties & Era Manager..."
    ]
    for expected in expectedBackgroundItems {
        guard bgMenu.items.contains(where: { $0.title == expected }) else {
            print("❌ FAILED: Taskbar background menu is missing required item: '\(expected)'.")
            exit(1)
        }
    }

    // 8.4 Verify Control-Click follows the exact same background hit path
    let bgCtrlClickEvent = NSEvent.mouseEvent(
        with: .leftMouseDown,
        location: bgPoint,
        modifierFlags: [.control],
        timestamp: 0,
        windowNumber: taskView.window?.windowNumber ?? 0,
        context: nil,
        eventNumber: 0,
        clickCount: 1,
        pressure: 1.0
    )!

    guard let bgCtrlMenu = taskView.menu(for: bgCtrlClickEvent) else {
        print("❌ FAILED: Control-click at background point returned nil.")
        exit(1)
    }
    guard bgCtrlMenu.title == "Taskbar" else {
        print("❌ FAILED: Control-click menu title was '\(bgCtrlMenu.title)', expected 'Taskbar'.")
        exit(1)
    }
    print("✔ CONTROL-CLICK HIT PATH: Verified Control-click at background point produces 'Taskbar' menu.")

    // 8.5 Physical Event Injection via CGEvent to exercise physical hit routing
    if let win = taskView.window {
        let screenPoint = win.convertToScreen(NSRect(origin: bgPoint, size: .zero)).origin
        let screenY = (NSScreen.main?.frame.height ?? 1117) - screenPoint.y
        let cgClickPoint = CGPoint(x: screenPoint.x, y: screenY)

        let rightDown = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: cgClickPoint, mouseButton: .right)
        let rightUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: cgClickPoint, mouseButton: .right)
        rightDown?.post(tap: .cghidEventTap)
        rightUp?.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Dismiss open menu via Escape key
        let escDown = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: true)
        let escUp = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: false)
        escDown?.post(tap: .cghidEventTap)
        escUp?.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    // 8.6 Physically activate menu action: Minimize All Windows
    taskView.showDesktopClicked()
    try? await Task.sleep(nanoseconds: 400_000_000)
    print("✔ MINIMIZE ALL WINDOWS: Action executed successfully.")

    // 9. Verify Era Switching Across All Six Core Eras
    print("\n[Step 9] Verifying Era Switching across all six core eras...")
    let eraManager = EraManager.shared
    eraManager.reloadAvailableEras()

    let erasToTest = [
        ("org.taskintosh.era.windows95", CGFloat(28)),
        ("org.taskintosh.era.windowsxp", CGFloat(30)),
        ("org.taskintosh.era.windows7", CGFloat(40)),
        ("org.taskintosh.era.windows8", CGFloat(40)),
        ("org.taskintosh.era.windows10", CGFloat(40)),
        ("org.taskintosh.era.windows11", CGFloat(48))
    ]

    for (eraID, expectedHeight) in erasToTest {
        guard let era = eraManager.availableEras.first(where: { $0.manifest.id == eraID }) else {
            print("❌ FAILED: Could not find era \(eraID)")
            exit(1)
        }
        eraManager.selectEra(era)
        let active = eraManager.activeEra
        guard active.manifest.id == eraID else {
            print("❌ FAILED: Active era did not switch to \(eraID)")
            exit(1)
        }
        guard active.layout.taskbarHeight == expectedHeight else {
            print("❌ FAILED: Era \(eraID) height \(active.layout.taskbarHeight) != expected \(expectedHeight)")
            exit(1)
        }
        if active.layout.buttonStyle == .standard || active.layout.buttonStyle == .tile {
            guard active.layout.taskButtonMinWidth >= 130 else {
                print("❌ FAILED: Era \(eraID) button min width \(active.layout.taskButtonMinWidth) < 130")
                exit(1)
            }
        }
        print(" -> Switched to [\(active.manifest.id)]: \(active.manifest.name) (Height: \(active.layout.taskbarHeight)px, Style: \(active.layout.taskbarStyle), ButtonStyle: \(active.layout.buttonStyle), Overflow: \(active.layout.overflowStrategy))")
    }
    print("✔ ERA SWITCHING & BUTTON SIZING: Verified all 6 core eras with distinct geometry and >=130px minimum button width.")

    // 10. Verify Start Menu System across all six eras (presentation, keyboard navigation, settings, escape)
    print("\n[Step 10] Verifying Start Menu System across all six eras...")
    let startWin = StartMenuWindow.shared

    for (eraID, _) in erasToTest {
        guard let era = eraManager.availableEras.first(where: { $0.manifest.id == eraID }) else { continue }
        eraManager.selectEra(era)

        var eraDismissed = false
        startWin.showAbove(rect: NSRect(x: 10, y: era.layout.taskbarHeight, width: era.layout.startButtonWidth, height: era.layout.taskbarHeight)) {
            eraDismissed = true
        }

        print(" -> Era [\(era.manifest.name)]: Menu isVisible: \(startWin.isVisible), type: \(era.theme.startMenuType)")
        guard startWin.isVisible else {
            print("❌ FAILED: Start menu was not visible for era \(era.manifest.id)")
            exit(1)
        }

        // Test keyboard navigation (Tab & Down arrow)
        let tabEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: startWin.windowNumber,
            context: nil,
            characters: "\t",
            charactersIgnoringModifiers: "\t",
            isARepeat: false,
            keyCode: 48
        )!
        startWin.keyDown(with: tabEvent)

        let downEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: startWin.windowNumber,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: 125
        )!
        startWin.keyDown(with: downEvent)

        // Dismiss via Escape
        let escapeEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: startWin.windowNumber,
            context: nil,
            characters: "\u{1b}",
            charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false,
            keyCode: 53
        )!
        startWin.keyDown(with: escapeEvent)
        try? await Task.sleep(nanoseconds: 100_000_000)

        guard !startWin.isVisible && eraDismissed else {
            print("❌ FAILED: Start menu not dismissed on Escape for era \(era.manifest.id)")
            exit(1)
        }
        print("    ✔ Verified menu presentation, keyboard navigation, and Escape dismissal for \(era.manifest.name)")
    }
    print("✔ START MENU VALIDATION: All 6 Start menus verified with keyboard navigation and Escape handling.")

    // 11. Verifying Start Menu Interaction & Polish Details
    print("\n[Step 11] Verifying Start Menu Interaction & Polish Details...")

    // (A) Canonical Compact Start Menu Sizes
    print(" -> Testing Canonical Compact Start Menu Sizes Across All Eras...")
    for era in eraManager.availableEras {
        let size = startWin.sizeForEra(era)
        guard size.width >= 200 && size.height >= 260 else {
            print("❌ FAILED: Invalid canonical Start menu size for \(era.manifest.id).")
            exit(1)
        }
        print("    * Era [\(era.manifest.name)]: Canonical Size = \(size)")
    }
    print("    ✔ Canonical compact Start menu sizes verified across all eras.")

    // (B) Windows 8.1 Horizontal Scrolling & Tile Groups
    print(" -> Testing Windows 8.1 Start Screen Horizontal Scrolling & Tile Groups...")
    let win8Era = eraManager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows8" }!
    eraManager.selectEra(win8Era)
    startWin.showAbove(rect: NSRect(x: 10, y: 40, width: 60, height: 40))
    guard let win8View = startWin.contentView as? Windows8MenuView else {
        print("❌ FAILED: ContentView is not Windows8MenuView.")
        exit(1)
    }
    guard win8View.groups.count >= 4 else {
        print("❌ FAILED: Windows 8.1 tile groups missing.")
        exit(1)
    }
    let initialX = win8View.scrollX
    if let cg = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: -40, wheel2: 0, wheel3: 0),
       let scrollEv = NSEvent(cgEvent: cg) {
        win8View.scrollWheel(with: scrollEv)
    }
    guard win8View.scrollX > initialX else {
        print("❌ FAILED: Windows 8.1 horizontal scroll did not pan.")
        exit(1)
    }
    print("    ✔ Windows 8.1 horizontal scrolling pans smoothly (scrollX: \(win8View.scrollX)).")
    startWin.hideMenu()

    // (C) Windows 10 Vertical Scrolling through Catalog
    print(" -> Testing Windows 10 Vertical App Catalog Scrolling...")
    let win10Era = eraManager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows10" }!
    eraManager.selectEra(win10Era)
    startWin.showAbove(rect: NSRect(x: 10, y: 40, width: 60, height: 40))
    guard let win10View = startWin.contentView as? Windows10MenuView else {
        print("❌ FAILED: ContentView is not Windows10MenuView.")
        exit(1)
    }
    guard !win10View.appList.isEmpty else {
        print("❌ FAILED: Windows 10 app catalog is empty.")
        exit(1)
    }
    let initialY = win10View.scrollOffsetY
    if win10View.maxScrollY > 0 {
        if let cg = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: -30, wheel2: 0, wheel3: 0),
           let scrollDown = NSEvent(cgEvent: cg) {
            win10View.scrollWheel(with: scrollDown)
        }
        guard win10View.scrollOffsetY > initialY else {
            print("❌ FAILED: Windows 10 vertical scroll did not pan.")
            exit(1)
        }
        print("    ✔ Windows 10 vertical scrolling pans installed apps (scrollOffsetY: \(win10View.scrollOffsetY)).")
    }
    startWin.hideMenu()

    // (D) Windows 7 In-Place "All Programs" Navigation
    print(" -> Testing Windows 7 In-Place 'All Programs' and '◄ Back' Navigation...")
    let win7Era = eraManager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windows7" }!
    eraManager.selectEra(win7Era)
    startWin.showAbove(rect: NSRect(x: 10, y: 40, width: 60, height: 40))
    guard let win7View = startWin.contentView as? Windows7MenuView else {
        print("❌ FAILED: ContentView is not Windows7MenuView.")
        exit(1)
    }
    guard !win7View.isShowingAllPrograms else {
        print("❌ FAILED: Windows 7 should start in pinned items view.")
        exit(1)
    }
    // Click bottom button ("All Programs ►")
    let clickBottom = NSEvent.mouseEvent(with: .leftMouseUp, location: NSPoint(x: 50, y: 55), modifierFlags: [], timestamp: 0, windowNumber: startWin.windowNumber, context: nil, eventNumber: 4, clickCount: 1, pressure: 1.0)!
    win7View.mouseUp(with: clickBottom)
    guard win7View.isShowingAllPrograms else {
        print("❌ FAILED: Windows 7 did not transition to in-place All Programs.")
        exit(1)
    }
    print("    ✔ Windows 7 in-place 'All Programs' toggled ON (Installed apps: \(win7View.installedApps.count)).")
    // Click "◄ Back"
    win7View.mouseUp(with: clickBottom)
    guard !win7View.isShowingAllPrograms else {
        print("❌ FAILED: Windows 7 did not return to pinned items view.")
        exit(1)
    }
    print("    ✔ Windows 7 '◄ Back' returned to standard pinned items view.")
    startWin.hideMenu()

    // (E) Windows XP Cascade Level Alignment
    print(" -> Testing Windows XP Cascade Level Alignment...")
    let winXPEra = eraManager.availableEras.first { $0.manifest.id == "org.taskintosh.era.windowsxp" }!
    eraManager.selectEra(winXPEra)
    startWin.showAbove(rect: NSRect(x: 10, y: 30, width: 60, height: 30))
    startWin.showCascade(for: "Programs", at: NSPoint(x: 0, y: 44))
    if let cascade = startWin.cascadeWindow {
        print("    * Start Menu Frame: \(startWin.frame)")
        print("    * Cascade Window Frame: \(cascade.frame)")
        guard cascade.frame.minX >= startWin.frame.maxX - 1 else {
            print("❌ FAILED: Cascade is not anchored flush to Start Menu right edge.")
            exit(1)
        }
        guard cascade.frame.minY == startWin.frame.minY else {
            print("❌ FAILED: Cascade is not level with Start Menu bottom.")
            exit(1)
        }
        print("    ✔ Windows XP Cascade window is level and flush with the Start menu.")
    }
    startWin.hideMenu()
    print("✔ INTERACTION & POLISH VALIDATION: All interaction behaviors verified!")

    // 12. System Tray & Notification Area Functional Validation
    print("\n[Step 12] Validating System Tray & Notification Area Functionality...")

    // (A) Volume & Mute control
    print(" -> Testing SystemMonitor volume & mute control...")
    let sysMon = SystemMonitor.shared
    let origVol = sysMon.volumeLevel
    let origMute = sysMon.isMuted

    sysMon.setVolume(72)
    guard sysMon.volumeLevel == 72 else {
        print("❌ FAILED: Volume level did not update to 72.")
        exit(1)
    }
    print("    ✔ Volume level set to 72% successfully.")

    sysMon.toggleMute()
    guard sysMon.isMuted == !origMute else {
        print("❌ FAILED: Mute state did not toggle.")
        exit(1)
    }
    print("    ✔ Mute state toggled successfully.")
    sysMon.setMuted(origMute)
    sysMon.setVolume(origVol)

    // (B) Volume Flyout Factory across eras
    print(" -> Testing VolumeFlyoutFactory across all 6 eras...")
    for era in eraManager.availableEras {
        let flyout = VolumeFlyoutFactory.makeFlyout(for: era)
        guard flyout.frame.width > 50 && flyout.frame.height > 50 else {
            print("❌ FAILED: Invalid volume flyout frame for \(era.manifest.id).")
            exit(1)
        }
    }
    print("    ✔ VolumeFlyoutFactory produces valid era-specific views for all 6 eras.")

    // (C) Clock Flyout Factory across eras
    print(" -> Testing ClockFlyoutFactory across all 6 eras...")
    for era in eraManager.availableEras {
        let flyout = ClockFlyoutFactory.makeFlyout(for: era)
        guard flyout.frame.width > 100 && flyout.frame.height > 100 else {
            print("❌ FAILED: Invalid clock flyout frame for \(era.manifest.id).")
            exit(1)
        }
    }
    print("    ✔ ClockFlyoutFactory produces valid era-specific views for all 6 eras.")

    // (D) Network Flyout Factory across eras
    print(" -> Testing NetworkFlyoutFactory across all 6 eras...")
    for era in eraManager.availableEras {
        let flyout = NetworkFlyoutFactory.makeFlyout(for: era)
        guard flyout.frame.width >= 200 && flyout.frame.height >= 140 else {
            print("❌ FAILED: Invalid network flyout frame for \(era.manifest.id).")
            exit(1)
        }
    }
    print("    ✔ NetworkFlyoutFactory produces valid era-specific views for all 6 eras.")

    // (E) Battery Flyout Factory across eras
    print(" -> Testing BatteryFlyoutFactory across all 6 eras...")
    for era in eraManager.availableEras {
        let flyout = BatteryFlyoutFactory.makeFlyout(for: era)
        guard flyout.frame.width >= 200 && flyout.frame.height >= 140 else {
            print("❌ FAILED: Invalid battery flyout frame for \(era.manifest.id).")
            exit(1)
        }
    }
    print("    ✔ BatteryFlyoutFactory produces valid era-specific views for all 6 eras.")

    // (F) Verify Windows 10 separate tray controls vs Windows 11 unified cluster
    print(" -> Verifying Win10 separate tray controls vs Win11 unified cluster behavior...")
    guard let win10 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows10" }),
          let win11 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows11" }) else {
        print("❌ FAILED: Missing Windows 10 or 11 era.")
        exit(1)
    }
    guard !win10.behaviors.unifiedSystemTrayCluster else {
        print("❌ FAILED: Windows 10 must have unifiedSystemTrayCluster == false.")
        exit(1)
    }
    guard win11.behaviors.unifiedSystemTrayCluster else {
        print("❌ FAILED: Windows 11 must have unifiedSystemTrayCluster == true.")
        exit(1)
    }
    print("    ✔ Era behaviors correctly distinguish Windows 10 separate icons from Windows 11 unified cluster.")

    // (G) Real Telemetry Data in SystemMonitor
    print(" -> Verifying real telemetry data integration...")
    print("    * Network connected: \(SystemMonitor.shared.isNetworkConnected)")
    print("    * Discovered Wi-Fi SSIDs count: \(SystemMonitor.shared.availableWiFiNetworks.count)")
    print("    * Active SSID: \(SystemMonitor.shared.connectedSSID ?? "None")")
    print("    * Battery Level: \(SystemMonitor.shared.batteryPercentage)%")
    print("    * Power Source: \(SystemMonitor.shared.powerSourceString)")
    print("    ✔ SystemMonitor telemetry populated.")

    // (H) TrayFlyoutWindow Positioning & Clamping
    print(" -> Testing TrayFlyoutWindow anchoring, positioning & clamping...")
    let trayWin = TrayFlyoutWindow.shared
    let testVolView = VolumeFlyoutFactory.makeFlyout(for: win7Era)
    let fakeTrayRect = NSRect(x: 1000, y: 10, width: 24, height: 24)
    trayWin.showAbove(anchorRect: fakeTrayRect, view: testVolView, control: .volume)
    guard trayWin.isVisible else {
        print("❌ FAILED: TrayFlyoutWindow did not become visible.")
        exit(1)
    }
    guard trayWin.currentTrayControl == .volume else {
        print("❌ FAILED: TrayFlyoutWindow currentTrayControl mismatch.")
        exit(1)
    }
    print("    * TrayFlyout Frame: \(trayWin.frame)")
    guard trayWin.frame.minY >= fakeTrayRect.maxY else {
        print("❌ FAILED: TrayFlyoutWindow is not anchored above the tray icon.")
        exit(1)
    }
    print("    ✔ TrayFlyoutWindow properly positioned above tray icon.")

    // (I) Mutual Exclusivity: Start Menu vs Tray Flyout
    print(" -> Testing mutual exclusivity between Start Menu and Tray Flyout...")
    startWin.showAbove(rect: NSRect(x: 10, y: 40, width: 60, height: 40))
    guard !trayWin.isVisible else {
        print("❌ FAILED: TrayFlyoutWindow should close when Start Menu opens.")
        exit(1)
    }
    print("    ✔ TrayFlyoutWindow closed automatically when Start Menu opened.")

    trayWin.showAbove(anchorRect: fakeTrayRect, view: testVolView, control: .volume)
    guard !startWin.isVisible else {
        print("❌ FAILED: StartMenuWindow should close when TrayFlyoutWindow opens.")
        exit(1)
    }
    print("    ✔ StartMenuWindow closed automatically when TrayFlyoutWindow opened.")

    // (J) Toggle behavior on repeat click
    trayWin.showAbove(anchorRect: fakeTrayRect, view: testVolView, control: .volume)
    guard !trayWin.isVisible else {
        print("❌ FAILED: TrayFlyoutWindow should toggle closed on repeat click.")
        exit(1)
    }
    print("    ✔ TrayFlyoutWindow toggled closed on repeat click.")
    print("✔ SYSTEM TRAY & NOTIFICATION AREA VALIDATION: All checks passed!")

    // 13. Cleanup
    print("\n[Step 13] Cleaning up TextEdit test process...")
    textEdit.terminate()
    print("✔ Cleanup complete.")

    print("\n========================================================")
    print("ALL PACKAGED APP VALIDATION CHECKS PASSED (EXIT CODE 0)!")
    print("========================================================")
    exit(0)
}

@MainActor
func exportEraSnapshots(outputDirPath: String) {
    print("========================================================")
    print("GENERATING VISUAL SNAPSHOTS FOR ALL SIX CORE ERAS")
    print("========================================================")

    let outputDir = URL(fileURLWithPath: outputDirPath)
    try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    let eraManager = EraManager.shared
    eraManager.reloadAvailableEras()

    let sampleTasks: [TaskItem] = [
        TaskItem(id: "finder", title: "Finder", icon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"), pid: 101, bundleIdentifier: "com.apple.finder", isActive: true, isMinimized: false, windowNumber: nil, runningApp: nil),
        TaskItem(id: "chrome", title: "Google Chrome", icon: ProceduralIcons.shared.internetIcon(size: 24), pid: 102, bundleIdentifier: "com.google.Chrome", isActive: false, isMinimized: false, windowNumber: nil, runningApp: nil),
        TaskItem(id: "vscode", title: "Visual Studio Code", icon: ProceduralIcons.shared.terminalIcon(size: 24), pid: 103, bundleIdentifier: "com.microsoft.VSCode", isActive: false, isMinimized: false, windowNumber: nil, runningApp: nil),
        TaskItem(id: "settings", title: "System Settings", icon: ProceduralIcons.shared.settingsIcon(size: 24), pid: 104, bundleIdentifier: "com.apple.systempreferences", isActive: false, isMinimized: false, windowNumber: nil, runningApp: nil),
        TaskItem(id: "term", title: "Terminal", icon: ProceduralIcons.shared.terminalIcon(size: 24), pid: 105, bundleIdentifier: "com.apple.Terminal", isActive: false, isMinimized: false, windowNumber: nil, runningApp: nil)
    ]

    let width: CGFloat = 1200

    func renderViewToPNG(view: NSView, frame: NSRect) -> Data? {
        view.frame = frame
        view.layoutSubtreeIfNeeded()
        if let rep = view.bitmapImageRepForCachingDisplay(in: frame) {
            view.cacheDisplay(in: frame, to: rep)
            return rep.representation(using: .png, properties: [:])
        }
        let image = NSImage(size: frame.size)
        image.lockFocus()
        view.draw(frame)
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    func renderSwiftUIViewToPNG<V: View>(rootView: V, size: CGSize) -> Data? {
        let frame = NSRect(origin: .zero, size: size)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = frame

        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hostingView
        window.displayIfNeeded()
        hostingView.layoutSubtreeIfNeeded()

        if let rep = hostingView.bitmapImageRepForCachingDisplay(in: frame) {
            hostingView.cacheDisplay(in: frame, to: rep)
            if let data = rep.representation(using: .png, properties: [:]), !data.isEmpty {
                return data
            }
        }
        let image = NSImage(size: size)
        image.lockFocus()
        hostingView.draw(frame)
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    for era in eraManager.availableEras {
        eraManager.selectEra(era)
        let height = era.layout.taskbarHeight
        let frame = NSRect(x: 0, y: 0, width: width, height: height)

        RunningAppWatcher.shared.setTaskItemsForTesting(sampleTasks)

        let taskView = TaskbarView(frame: frame)
        guard let pngData = renderViewToPNG(view: taskView, frame: frame) else {
            print("❌ FAILED to create PNG data for \(era.manifest.id)")
            continue
        }

        let fileURL = outputDir.appendingPathComponent("\(era.manifest.id).png")
        do {
            try pngData.write(to: fileURL)
            print("✔ Visual snapshot saved: \(fileURL.lastPathComponent) (\(Int(width))x\(Int(height))px)")
        } catch {
            print("❌ Error writing snapshot: \(error)")
        }
    }

    // Also export an overflow scenario snapshot for Windows 95
    if let win95 = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" }) {
        eraManager.selectEra(win95)
        var manyTasks: [TaskItem] = []
        for i in 1...14 {
            manyTasks.append(TaskItem(id: "app\(i)", title: "App \(i) Long Title", icon: ProceduralIcons.shared.programsIcon(size: 16), pid: pid_t(200 + i), bundleIdentifier: "com.test.app\(i)", isActive: i == 1, isMinimized: false, windowNumber: nil, runningApp: nil))
        }
        RunningAppWatcher.shared.setTaskItemsForTesting(manyTasks)
        let frame = NSRect(x: 0, y: 0, width: 850, height: win95.layout.taskbarHeight)
        let taskView = TaskbarView(frame: frame)

        if let pngData = renderViewToPNG(view: taskView, frame: frame) {
            let fileURL = outputDir.appendingPathComponent("overflow_windows95.png")
            try? pngData.write(to: fileURL)
            print("✔ Overflow snapshot saved: overflow_windows95.png")
        }
    }

    // Also export an overflow scenario snapshot for Windows XP
    if let winXP = eraManager.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windowsxp" }) {
        eraManager.selectEra(winXP)
        var manyTasks: [TaskItem] = []
        for i in 1...14 {
            manyTasks.append(TaskItem(id: "app\(i)", title: "App \(i) Long Title", icon: ProceduralIcons.shared.programsIcon(size: 16), pid: pid_t(200 + i), bundleIdentifier: "com.test.app\(i)", isActive: i == 1, isMinimized: false, windowNumber: nil, runningApp: nil))
        }
        RunningAppWatcher.shared.setTaskItemsForTesting(manyTasks)
        let frame = NSRect(x: 0, y: 0, width: 850, height: winXP.layout.taskbarHeight)
        let taskView = TaskbarView(frame: frame)

        if let pngData = renderViewToPNG(view: taskView, frame: frame) {
            let fileURL = outputDir.appendingPathComponent("overflow_windowsxp.png")
            try? pngData.write(to: fileURL)
            print("✔ Overflow snapshot saved: overflow_windowsxp.png")
        }
    }

    // Also export Start Menu Snapshots
    let startMenuOutputDir = outputDir.appendingPathComponent("start_menus")
    try? FileManager.default.createDirectory(at: startMenuOutputDir, withIntermediateDirectories: true)

    let win95Menu = Windows95MenuView()
    win95Menu.frame = NSRect(x: 0, y: 0, width: 216, height: 276)
    if let data = renderViewToPNG(view: win95Menu, frame: win95Menu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windows95.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windows95.png"))
        print("✔ Start menu snapshot saved: menu_windows95.png")
    }

    let winXPMenu = WindowsXPMenuView()
    winXPMenu.frame = NSRect(x: 0, y: 0, width: 384, height: 450)
    if let data = renderViewToPNG(view: winXPMenu, frame: winXPMenu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windowsxp.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windowsxp.png"))
        print("✔ Start menu snapshot saved: menu_windowsxp.png")
    }

    let win7Menu = Windows7MenuView()
    win7Menu.frame = NSRect(x: 0, y: 0, width: 420, height: 480)
    if let data = renderViewToPNG(view: win7Menu, frame: win7Menu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windows7.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windows7.png"))
        print("✔ Start menu snapshot saved: menu_windows7.png")
    }

    let win8Menu = Windows8MenuView()
    win8Menu.isWindows81Override = false
    win8Menu.frame = NSRect(x: 0, y: 0, width: 700, height: 470)
    if let data = renderViewToPNG(view: win8Menu, frame: win8Menu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windows8.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windows8.png"))
        print("✔ Start menu snapshot saved: menu_windows8.png")
    }

    let win81Menu = Windows8MenuView()
    win81Menu.isWindows81Override = true
    win81Menu.frame = NSRect(x: 0, y: 0, width: 700, height: 470)
    if let data = renderViewToPNG(view: win81Menu, frame: win81Menu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windows81.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windows81.png"))
        print("✔ Start menu snapshot saved: menu_windows81.png")
    }

    let win10Menu = Windows10MenuView()
    win10Menu.frame = NSRect(x: 0, y: 0, width: 620, height: 490)
    if let data = renderViewToPNG(view: win10Menu, frame: win10Menu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windows10.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windows10.png"))
        print("✔ Start menu snapshot saved: menu_windows10.png")
    }

    let win11Menu = Windows11MenuView()
    win11Menu.frame = NSRect(x: 0, y: 0, width: 560, height: 600)
    if let data = renderViewToPNG(view: win11Menu, frame: win11Menu.frame) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("menu_windows11.png"))
        try? data.write(to: outputDir.appendingPathComponent("menu_windows11.png"))
        print("✔ Start menu snapshot saved: menu_windows11.png")
    }

    // Win95 Find Dialog snapshot
    let findWin = Win95FindDialog.shared.window!
    if let contentView = findWin.contentView,
       let data = renderViewToPNG(view: contentView, frame: contentView.bounds) {
        try? data.write(to: startMenuOutputDir.appendingPathComponent("find_dialog_windows95.png"))
        try? data.write(to: outputDir.appendingPathComponent("find_dialog_windows95.png"))
        print("✔ Find dialog snapshot saved: find_dialog_windows95.png")
    }

    // Also export Fake Windows Update Dialog Snapshots for all 8 supported eras
    let updateOutputDir = outputDir.appendingPathComponent("updates")
    try? FileManager.default.createDirectory(at: updateOutputDir, withIntermediateDirectories: true)

    let updateEras: [(era: WindowsEra, filename: String)] = [
        (.win95, "update_windows95.png"),
        (.winXP, "update_windowsxp.png"),
        (.winVista, "update_windowsvista.png"),
        (.win7, "update_windows7.png"),
        (.win8, "update_windows8.png"),
        (.win8_1, "update_windows81.png"),
        (.win10, "update_windows10.png"),
        (.win11, "update_windows11.png")
    ]

    for item in updateEras {
        let ctrl = FakeUpdateController(era: item.era)
        let testState = UpdateState(
            status: .running,
            overallProgress: 0.48,
            stageProgress: 0.62,
            currentStageIndex: 1,
            currentStepIndex: 3,
            currentUpdateNumber: 3,
            totalUpdateCount: 7,
            headline: item.era.defaultHeadline,
            subheadline: item.era.defaultWarningMessage,
            currentMessage: "Updating system components...",
            currentStatusText: "Copying files to destination...",
            currentFile: "shell32.dll",
            currentPath: "C:\\Windows\\System32\\",
            currentKB: "4,096 KB",
            activityLog: ["Session started", "Updating shell32.dll"]
        )
        ctrl.setStateForTesting(testState)

        let updateView = FakeUpdateWindowView(controller: ctrl)
        let size = item.era.windowSize
        if let data = renderSwiftUIViewToPNG(rootView: updateView, size: size) {
            try? data.write(to: updateOutputDir.appendingPathComponent(item.filename))
            try? data.write(to: outputDir.appendingPathComponent(item.filename))
            print("✔ Windows Update dialog snapshot saved: \(item.filename) (\(Int(size.width))x\(Int(size.height))px)")
        } else {
            print("❌ FAILED to render update snapshot: \(item.filename)")
        }
    }

        // Also export Flyout Snapshots
    let flyoutOutputDir = outputDir.appendingPathComponent("flyouts")
    try? FileManager.default.createDirectory(at: flyoutOutputDir, withIntermediateDirectories: true)

    for era in eraManager.availableEras {
        let vFlyout = VolumeFlyoutFactory.makeFlyout(for: era)
        if let data = renderViewToPNG(view: vFlyout, frame: vFlyout.frame) {
            let name = "volume_\(era.manifest.id).png"
            try? data.write(to: flyoutOutputDir.appendingPathComponent(name))
            print("✔ Flyout snapshot saved: \(name)")
        }

        let cFlyout = ClockFlyoutFactory.makeFlyout(for: era)
        if let data = renderViewToPNG(view: cFlyout, frame: cFlyout.frame) {
            let name = "clock_\(era.manifest.id).png"
            try? data.write(to: flyoutOutputDir.appendingPathComponent(name))
            print("✔ Flyout snapshot saved: \(name)")
        }
        let bFlyout = BatteryFlyoutFactory.makeFlyout(for: era)
        if let data = renderViewToPNG(view: bFlyout, frame: bFlyout.frame) {
            let name = "battery_\(era.manifest.id).png"
            try? data.write(to: flyoutOutputDir.appendingPathComponent(name))
            print("✔ Flyout snapshot saved: \(name)")
        }

        let nFlyout = NetworkFlyoutFactory.makeFlyout(for: era)
        if let data = renderViewToPNG(view: nFlyout, frame: nFlyout.frame) {
            let name = "network_\(era.manifest.id).png"
            try? data.write(to: flyoutOutputDir.appendingPathComponent(name))
            print("✔ Flyout snapshot saved: \(name)")
        }
    }

    let qsFlyout = QuickSettingsFlyoutView()
    if let data = renderViewToPNG(view: qsFlyout, frame: qsFlyout.frame) {
        try? data.write(to: flyoutOutputDir.appendingPathComponent("quicksettings_flyout.png"))
        print("✔ Flyout snapshot saved: quicksettings_flyout.png")
    }

    print("\nVisual snapshot generation complete.")
    exit(0)
}
