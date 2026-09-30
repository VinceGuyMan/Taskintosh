import AppKit
import ApplicationServices
import CoreGraphics
import TaskintoshKit

/// Keeps other applications' windows out of the space occupied by Taskintosh's taskbar.
/// macOS does not reserve screen space for an ordinary NSPanel, so this uses the
/// Accessibility API only when the user has granted Taskintosh permission.
final class TaskbarWindowLayoutCoordinator {
    private struct WindowAdjustment {
        let element: AXUIElement
        let originalFrame: CGRect
        let adjustedFrame: CGRect
    }

    private var adjustments: [WindowAdjustment] = []
    private var taskbarFrame: CGRect?
    private var edge: TaskbarEdge?
    private var screenFrames: [CGRect] = []
    private var isActive = false
    private var workspaceObservers: [NSObjectProtocol] = []

    init() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ] {
            workspaceObservers.append(center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                // Give the activated app a moment to finish creating its windows.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self?.adjustNewWindowsIfNeeded()
                }
            })
        }
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach { center.removeObserver($0) }
    }

    func update(taskbarFrame: CGRect, edge: TaskbarEdge, screens: [NSScreen], isActive: Bool) {
        let newScreenFrames = screens.map(\.frame)
        let geometryChanged = self.taskbarFrame != taskbarFrame || self.edge != edge || screenFrames != newScreenFrames

        if !isActive {
            restoreAdjustedWindows()
            self.isActive = false
            self.taskbarFrame = nil
            self.edge = nil
            self.screenFrames = newScreenFrames
            return
        }

        if !self.isActive || geometryChanged {
            restoreAdjustedWindows()
            self.taskbarFrame = taskbarFrame
            self.edge = edge
            self.screenFrames = newScreenFrames
        }

        self.isActive = true
        adjustNewWindowsIfNeeded(screens: screens)
    }

    func releaseReservedSpace() {
        restoreAdjustedWindows()
        isActive = false
        taskbarFrame = nil
        edge = nil
    }

    private func adjustNewWindowsIfNeeded(screens: [NSScreen] = NSScreen.screens) {
        guard isActive,
              let taskbarFrame,
              let edge,
              WindowAccessibilityBridge.shared.isAccessibilityTrusted else { return }

        let ownPID = NSRunningApplication.current.processIdentifier
        let applications = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != ownPID && !$0.isHidden
        }

        for application in applications {
            let appElement = AXUIElementCreateApplication(application.processIdentifier)
            var windowsValue: AnyObject?
            guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
                  let windows = windowsValue as? [AXUIElement] else { continue }

            for window in windows {
                guard !isAlreadyManaged(window),
                      isVisibleWindow(window),
                      let originalFrame = readFrame(of: window),
                      let adjustedFrame = adjustedFrame(
                        originalFrame,
                        taskbarFrame: taskbarFrame,
                        edge: edge,
                        screens: screens
                      ),
                      adjustedFrame != originalFrame,
                      setFrame(adjustedFrame, of: window) else { continue }

                let appliedFrame = readFrame(of: window) ?? adjustedFrame
                guard !approximatelyEqual(appliedFrame, originalFrame) else { continue }

                adjustments.append(WindowAdjustment(
                    element: window,
                    originalFrame: originalFrame,
                    adjustedFrame: appliedFrame
                ))
            }
        }
    }

    private func adjustedFrame(
        _ windowFrame: CGRect,
        taskbarFrame: CGRect,
        edge: TaskbarEdge,
        screens: [NSScreen]
    ) -> CGRect? {
        let mainScreenTop = mainDisplayTop(screens: screens)
        let taskbarAXFrame = accessibilityFrame(taskbarFrame, mainScreenTop: mainScreenTop)

        for screen in screens {
            let screenAXFrame = accessibilityFrame(screen.frame, mainScreenTop: mainScreenTop)
            let reservedFrame = taskbarAXFrame.intersection(screenAXFrame)
            guard !reservedFrame.isNull, windowFrame.intersects(reservedFrame) else { continue }

            var workArea = screenAXFrame
            switch edge {
            case .bottom:
                workArea.size.height = max(0, reservedFrame.minY - screenAXFrame.minY)
            case .top:
                let newMinY = reservedFrame.maxY
                workArea.size.height = max(0, screenAXFrame.maxY - newMinY)
                workArea.origin.y = newMinY
            case .left:
                let newMinX = reservedFrame.maxX
                workArea.size.width = max(0, screenAXFrame.maxX - newMinX)
                workArea.origin.x = newMinX
            case .right:
                workArea.size.width = max(0, reservedFrame.minX - screenAXFrame.minX)
            }

            guard workArea.width > 0, workArea.height > 0 else { return nil }
            return fit(windowFrame, inside: workArea, for: edge)
        }

        return nil
    }

    private func fit(_ frame: CGRect, inside workArea: CGRect, for edge: TaskbarEdge) -> CGRect {
        var result = frame

        switch edge {
        case .bottom, .top:
            if result.height > workArea.height {
                result.origin.y = workArea.minY
                result.size.height = workArea.height
            } else if edge == .bottom {
                result.origin.y = min(result.origin.y, workArea.maxY - result.height)
                result.origin.y = max(result.origin.y, workArea.minY)
            } else {
                result.origin.y = max(result.origin.y, workArea.minY)
            }
        case .left, .right:
            if result.width > workArea.width {
                result.origin.x = workArea.minX
                result.size.width = workArea.width
            } else if edge == .left {
                result.origin.x = max(result.origin.x, workArea.minX)
            } else {
                result.origin.x = min(result.origin.x, workArea.maxX - result.width)
                result.origin.x = max(result.origin.x, workArea.minX)
            }
        }

        return result
    }

    private func isVisibleWindow(_ window: AXUIElement) -> Bool {
        var roleValue: AnyObject?
        if AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String,
           role != (kAXWindowRole as String) {
            return false
        }

        if booleanAttribute(kAXMinimizedAttribute as CFString, of: window) == true ||
            booleanAttribute("AXFullScreen" as CFString, of: window) == true {
            return false
        }

        return true
    }

    private func booleanAttribute(_ attribute: CFString, of element: AXUIElement) -> Bool? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let number = value as? NSNumber else { return nil }
        return number.boolValue
    }

    private func isAlreadyManaged(_ element: AXUIElement) -> Bool {
        adjustments.contains { CFEqual($0.element, element) }
    }

    private func restoreAdjustedWindows() {
        guard WindowAccessibilityBridge.shared.isAccessibilityTrusted else {
            adjustments.removeAll()
            return
        }

        for adjustment in adjustments {
            // Preserve any window the user moved or resized after Taskintosh adjusted it.
            guard let currentFrame = readFrame(of: adjustment.element),
                  approximatelyEqual(currentFrame, adjustment.adjustedFrame) else { continue }
            _ = setFrame(adjustment.originalFrame, of: adjustment.element)
        }
        adjustments.removeAll()
    }

    private func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) < 2 &&
        abs(lhs.minY - rhs.minY) < 2 &&
        abs(lhs.width - rhs.width) < 2 &&
        abs(lhs.height - rhs.height) < 2
    }

    private func readFrame(of element: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionObject = positionValue,
              let sizeObject = sizeValue,
              CFGetTypeID(positionObject) == AXValueGetTypeID(),
              CFGetTypeID(sizeObject) == AXValueGetTypeID() else { return nil }

        let positionAXValue = positionObject as! AXValue
        let sizeAXValue = sizeObject as! AXValue

        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionAXValue, .cgPoint, &origin),
              AXValueGetValue(sizeAXValue, .cgSize, &size),
              size.width > 0,
              size.height > 0 else { return nil }
        return CGRect(origin: origin, size: size)
    }

    @discardableResult
    private func setFrame(_ frame: CGRect, of element: AXUIElement) -> Bool {
        guard let previousFrame = readFrame(of: element) else { return false }

        let sizeChanged = abs(frame.width - previousFrame.width) > 0.5 || abs(frame.height - previousFrame.height) > 0.5
        if sizeChanged {
            var size = frame.size
            guard let sizeValue = AXValueCreate(.cgSize, &size),
                  AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue) == .success else {
                return false
            }
        }

        let positionChanged = abs(frame.minX - previousFrame.minX) > 0.5 || abs(frame.minY - previousFrame.minY) > 0.5
        if positionChanged {
            var position = frame.origin
            guard let positionValue = AXValueCreate(.cgPoint, &position),
                  AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue) == .success else {
                if sizeChanged {
                    _ = setFrameValues(previousFrame, of: element)
                }
                return false
            }
        }
        return true
    }

    private func setFrameValues(_ frame: CGRect, of element: AXUIElement) -> Bool {
        guard let previousFrame = readFrame(of: element) else { return false }

        let sizeChanged = abs(frame.width - previousFrame.width) > 0.5 || abs(frame.height - previousFrame.height) > 0.5
        if sizeChanged {
            var size = frame.size
            guard let sizeValue = AXValueCreate(.cgSize, &size),
                  AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue) == .success else {
                return false
            }
        }

        let positionChanged = abs(frame.minX - previousFrame.minX) > 0.5 || abs(frame.minY - previousFrame.minY) > 0.5
        if positionChanged {
            var position = frame.origin
            guard let positionValue = AXValueCreate(.cgPoint, &position),
                  AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue) == .success else {
                return false
            }
        }
        return true
    }

    private func accessibilityFrame(_ frame: CGRect, mainScreenTop: CGFloat) -> CGRect {
        CGRect(
            x: frame.minX,
            y: mainScreenTop - frame.maxY,
            width: frame.width,
            height: frame.height
        )
    }

    private func mainDisplayTop(screens: [NSScreen]) -> CGFloat {
        let mainDisplayID = CGMainDisplayID()
        let mainScreen = screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return number.uint32Value == mainDisplayID
        }
        return mainScreen?.frame.maxY ?? screens.first?.frame.maxY ?? 0
    }
}
