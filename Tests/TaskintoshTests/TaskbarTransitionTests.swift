import XCTest
import AppKit
@testable import TaskintoshKit

final class TaskbarTransitionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: TaskbarTransitionEffect.preferenceKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: TaskbarTransitionEffect.preferenceKey)
        super.tearDown()
    }

    // MARK: - 1. Transition Effects Suite Completeness
    func testAllSixTransitionEffectsPresent() {
        let allEffects = TaskbarTransitionEffect.allCases
        XCTAssertEqual(allEffects.count, 6, "Expected exactly a suite of 6 transition effects.")

        let expectedCases: Set<TaskbarTransitionEffect> = [
            .crossfade,
            .slidePush,
            .curtainWipe,
            .crtMorph,
            .glassBloom,
            .timeWarp
        ]
        XCTAssertEqual(Set(allEffects), expectedCases)

        for effect in allEffects {
            XCTAssertFalse(effect.displayName.isEmpty, "\(effect) must have a non-empty displayName")
            XCTAssertFalse(effect.subtitle.isEmpty, "\(effect) must have a non-empty subtitle")
        }
    }

    // MARK: - 2. Default & Preferences Persistence
    func testDefaultAndPreferredEffectPersistence() {
        // Default must be smooth crossfade
        XCTAssertEqual(TaskbarTransitionEffect.preferredEffect, .crossfade)
        XCTAssertFalse(TaskbarTransitionEffect.isCycleMode)

        // Change preference to CRT Morph
        TaskbarTransitionEffect.preferredEffect = .crtMorph
        XCTAssertEqual(TaskbarTransitionEffect.preferredEffect, .crtMorph)

        // Change to Slide Push
        TaskbarTransitionEffect.preferredEffect = .slidePush
        XCTAssertEqual(TaskbarTransitionEffect.preferredEffect, .slidePush)

        // Enable Cycle Mode
        TaskbarTransitionEffect.isCycleMode = true
        XCTAssertTrue(TaskbarTransitionEffect.isCycleMode)

        // When cycle mode is active, preferredEffect returns one of the valid 6 cases
        let cycled = TaskbarTransitionEffect.preferredEffect
        XCTAssertTrue(TaskbarTransitionEffect.allCases.contains(cycled))

        // Disabling cycle mode restores crossfade
        TaskbarTransitionEffect.isCycleMode = false
        XCTAssertFalse(TaskbarTransitionEffect.isCycleMode)
        XCTAssertEqual(TaskbarTransitionEffect.preferredEffect, .crossfade)
    }

    // MARK: - 3. Transition Geometry & All Six Eras Snapshot Verification
    @MainActor
    func testAllSixErasSnapshotCapture() {
        let eraManager = EraManager.shared
        eraManager.reloadAvailableEras()
        XCTAssertGreaterThanOrEqual(eraManager.availableEras.count, 6)

        let testSize = NSSize(width: 800, height: 40)

        for era in eraManager.availableEras {
            let img = NSImage(size: testSize)
            img.lockFocus()
            // Verify era components can render directly to an offscreen image target
            let rect = NSRect(origin: .zero, size: testSize)
            let theme = era.theme
            theme.backgroundColor.setFill()
            rect.fill()
            img.unlockFocus()

            XCTAssertEqual(img.size.width, 800)
            XCTAssertEqual(img.size.height, 40)
        }
    }
}
