import Foundation
import Combine
import AppKit

/// Public integration facade for Taskintosh.
/// Allows the main app or menu systems to initiate theatrical fake updates with zero coupling.
public struct FakeUpdateSystem {

    /// Shared singleton controller if single-instance coordination is preferred
    @MainActor
    public static let shared = FakeUpdateController()

    /// Currently active update window controller for real Taskintosh desktop presentation
    @MainActor
    public static var activeWindowController: FakeUpdateWindowController?

    /// Presents the era-authentic update window directly over the existing Taskintosh desktop.
    /// - Does not draw any simulated desktop canvas or background square.
    /// - Tightly sizes the popup window to the era's exact renderer dimensions (e.g. 350x195 for Win95).
    /// - Native macOS chrome and traffic lights are suppressed.
    @MainActor
    @discardableResult
    public static func present(
        era: WindowsEra,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .authentic,
        seed: UInt64? = nil,
        onCompletion: ((UpdateSession) -> Void)? = nil
    ) -> FakeUpdateWindowController {
        let controller = shared
        controller.onCompletion = onCompletion

        let windowController = activeWindowController ?? FakeUpdateWindowController(controller: controller, cleanPresentationMode: true)
        self.activeWindowController = windowController
        windowController.present(era: era, duration: duration, personality: personality, seed: seed)
        return windowController
    }

    /// Presents the update window dynamically resolved from a Taskintosh era manifest identifier string.
    @MainActor
    @discardableResult
    public static func present(
        taskintoshEraID: String,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .authentic,
        seed: UInt64? = nil,
        onCompletion: ((UpdateSession) -> Void)? = nil
    ) -> FakeUpdateWindowController {
        let era = WindowsEra.from(taskintoshEraID: taskintoshEraID)
        return present(
            era: era,
            duration: duration,
            personality: personality,
            seed: seed,
            onCompletion: onCompletion
        )
    }

    /// Starts a fake update session using a strongly typed `WindowsEra` (headless / state-only).
    @MainActor
    @discardableResult
    public static func startFakeUpdate(
        era: WindowsEra,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .standard,
        seed: UInt64? = nil,
        onCompletion: ((UpdateSession) -> Void)? = nil
    ) -> FakeUpdateController {
        let controller = shared
        controller.onCompletion = onCompletion
        controller.start(
            era: era,
            duration: duration,
            personality: personality,
            seed: seed
        )
        return controller
    }

    /// Starts a fake update session dynamically resolved from a Taskintosh era manifest identifier string (headless / state-only).
    @MainActor
    @discardableResult
    public static func startFakeUpdate(
        taskintoshEraID: String,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .standard,
        seed: UInt64? = nil,
        onCompletion: ((UpdateSession) -> Void)? = nil
    ) -> FakeUpdateController {
        let era = WindowsEra.from(taskintoshEraID: taskintoshEraID)
        return startFakeUpdate(
            era: era,
            duration: duration,
            personality: personality,
            seed: seed,
            onCompletion: onCompletion
        )
    }

    /// Creates an independent controller instance for preview or custom window presentation.
    @MainActor
    public static func makeController(era: WindowsEra = .win7) -> FakeUpdateController {
        FakeUpdateController(era: era)
    }
}

/// Thread-safe execution wrapper guaranteeing that an action closure is invoked at most once.
public final class OnceAction: @unchecked Sendable {
    private let lock = NSLock()
    private var hasFired = false
    private let action: () -> Void

    public init(_ action: @escaping () -> Void) {
        self.action = action
    }

    public func callAsFunction() {
        lock.lock()
        defer { lock.unlock() }
        guard !hasFired else { return }
        hasFired = true
        action()
    }
}
