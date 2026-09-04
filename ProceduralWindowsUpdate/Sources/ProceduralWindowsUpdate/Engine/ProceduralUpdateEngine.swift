import Foundation

/// The core deterministic procedural generation engine for fake Windows Update sessions.
/// Completely decoupled from the filesystem, network, and system commands.
public final class ProceduralUpdateEngine: Sendable {

    public init() {}

    /// Generates a complete, deterministic `UpdateSession` using the specified parameters.
    public func generateSession(
        era: WindowsEra,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .authentic,
        seed: UInt64? = nil
    ) -> UpdateSession {
        let effectiveSeed = seed ?? UInt64.random(in: 1...UInt64.max)
        var rng = SplitMix64(seed: effectiveSeed)

        // 1. Determine base update count based on era
        let initialUpdateCount: Int
        switch era {
        case .win95, .win98, .winME:
            initialUpdateCount = rng.nextInt(in: 1...3)
        case .winXP:
            initialUpdateCount = rng.nextInt(in: 3...6)
        case .winVista, .win7:
            initialUpdateCount = rng.nextInt(in: 4...9)
        case .win8, .win8_1:
            initialUpdateCount = rng.nextInt(in: 2...5)
        case .win10, .win11:
            initialUpdateCount = rng.nextInt(in: 2...6)
        }

        // 2. Determine rare events for this session ONLY if theatrical mode is enabled
        var sessionRareEvents: [RareEvent] = []

        if personality.allowsTheatricalEasterEggs {
            // Seed 42 or specific chance triggers canonical line
            if effectiveSeed == 42 || rng.chance(0.20) {
                sessionRareEvents.append(.canonicalMetaUpdate)
            }
            if rng.chance(0.18) {
                sessionRareEvents.append(.fakeGlitchAndRecovery)
            }
            if rng.chance(0.16) {
                sessionRareEvents.append(.midSessionCountIncrease)
            }
            if rng.chance(0.15) {
                sessionRareEvents.append(.servicePackVibes)
            }
            if rng.chance(0.15) {
                sessionRareEvents.append(.taskintoshCompatibilityRollup)
            }
            if rng.chance(0.15) {
                sessionRareEvents.append(.cleaningUpOldVibes)
            }
            if rng.chance(0.12) {
                sessionRareEvents.append(.clippyEmploymentCheck)
            }
            if rng.chance(0.12) {
                sessionRareEvents.append(.restoreStartMenuDignity)
            }
            if rng.chance(0.12) {
                sessionRareEvents.append(.deleteTempPsd)
            }
            if rng.chance(0.12) {
                sessionRareEvents.append(.suspiciouslyHelpfulDll)
            }
            if rng.chance(0.12) {
                sessionRareEvents.append(.wholesomeAffirmation)
            }
        }

        // 3. Generate fake update items
        var updates: [FakeUpdateItem] = []
        for i in 1...initialUpdateCount {
            let item = KBGenerator.generateUpdate(
                era: era,
                index: i,
                total: initialUpdateCount,
                rng: &rng,
                forceVibes: sessionRareEvents.contains(.taskintoshCompatibilityRollup) && (i == initialUpdateCount)
            )
            updates.append(item)
        }

        // 4. Generate structured stages
        let stagesBlueprint: [(kind: StageKind, start: Double, end: Double)] = [
            (.checking, 0.00, 0.08),
            (.downloading, 0.08, 0.28),
            (.verifying, 0.28, 0.36),
            (.installing, 0.36, 0.74),
            (.configuring, 0.74, 0.88),
            (.cleaningUp, 0.88, 0.96),
            (.restarting, 0.96, 0.99),
            (.finalizing, 0.99, 1.00)
        ]

        var constructedStages: [UpdateStage] = []
        var allSteps: [UpdateStep] = []

        let durationSeconds = duration.targetDurationSeconds
        let targetTotalSteps = max(18, Int(Double(32) * duration.stepCountMultiplier))

        var currentTotalUpdates = initialUpdateCount
        var hasBumpedCount = false
        var hasTriggeredGlitch = false
        var currentGlobalProgress = 0.0

        for (stageIndex, blueprint) in stagesBlueprint.enumerated() {
            let stageKind = blueprint.kind
            let stageStart = blueprint.start
            let stageEnd = blueprint.end

            let stageWeight: Double
            switch stageKind {
            case .checking: stageWeight = 0.08
            case .downloading: stageWeight = 0.20
            case .verifying: stageWeight = 0.08
            case .installing: stageWeight = 0.38
            case .configuring: stageWeight = 0.14
            case .cleaningUp: stageWeight = 0.08
            case .restarting: stageWeight = 0.03
            case .finalizing: stageWeight = 0.01
            }

            let stageStepCount = max(2, Int(round(Double(targetTotalSteps) * stageWeight)))
            var stageSteps: [UpdateStep] = []

            for stepIdx in 0..<stageStepCount {
                let frac = Double(stepIdx + 1) / Double(stageStepCount)
                var rawProgress = stageStart + (stageEnd - stageStart) * frac

                var isStall = false
                var isJump = false
                var isRegression = false
                var isRestartPoint = false
                var activeRareEventForStep: RareEvent? = nil

                // Check for mid-session count increase rare event (theatrical only)
                if stageKind == .installing && frac > 0.4 && !hasBumpedCount && sessionRareEvents.contains(.midSessionCountIncrease) {
                    hasBumpedCount = true
                    currentTotalUpdates += 3
                    activeRareEventForStep = .midSessionCountIncrease
                    isStall = true
                }

                // Check for glitch & recovery during installing (theatrical only)
                if stageKind == .installing && frac > 0.6 && !hasTriggeredGlitch && sessionRareEvents.contains(.fakeGlitchAndRecovery) {
                    hasTriggeredGlitch = true
                    activeRareEventForStep = .fakeGlitchAndRecovery
                    isRegression = true
                    rawProgress = max(stageStart, rawProgress - 0.03)
                }

                // Check for canonical meta update line (theatrical only)
                if (stageKind == .installing || stageKind == .downloading) && activeRareEventForStep == nil && sessionRareEvents.contains(.canonicalMetaUpdate) && rng.chance(0.18) {
                    activeRareEventForStep = .canonicalMetaUpdate
                }

                // Check for other rare events (theatrical only)
                if activeRareEventForStep == nil && !sessionRareEvents.isEmpty && rng.chance(0.12) {
                    activeRareEventForStep = rng.choose(from: sessionRareEvents)
                }

                // Procedural pacing behaviors:
                // 1. Stalls (e.g. around 17%, 42%, 73%, and 99%)
                if !isStall && (rawProgress > 0.16 && rawProgress < 0.19 || rawProgress > 0.41 && rawProgress < 0.44 || rawProgress > 0.72 && rawProgress < 0.75 || rawProgress >= 0.985) {
                    isStall = true
                }

                // 2. Percentage jumps
                if !isStall && !isRegression && stageKind == .downloading && stepIdx == stageStepCount - 1 && rng.chance(0.35) {
                    isJump = true
                    rawProgress = min(stageEnd, rawProgress + 0.04)
                }

                // 3. Simulated restart stage
                if stageKind == .restarting {
                    isRestartPoint = true
                }

                currentGlobalProgress = min(max(rawProgress, 0.0), 1.0)

                // Calculate which update item is currently being processed
                let currentItemIndex: Int
                let activeKB: String?
                if updates.isEmpty {
                    currentItemIndex = 1
                    activeKB = nil
                } else {
                    let uIdx = min(updates.count - 1, max(0, Int(Double(updates.count) * currentGlobalProgress)))
                    currentItemIndex = min(currentTotalUpdates, uIdx + 1)
                    activeKB = updates[uIdx].kbIdentifier
                }

                let (file, path) = ContentPools.pickFileAndPath(era: era, intensity: personality, rareEvent: activeRareEventForStep, rng: &rng)
                let message = ContentPools.pickMessage(
                    era: era,
                    stage: stageKind,
                    intensity: personality,
                    rareEvent: activeRareEventForStep,
                    rng: &rng
                )

                // Compute realistic status line
                let statusText: String
                switch stageKind {
                case .checking:
                    statusText = (era == .win95 || era == .win98 || era == .winME)
                        ? "Please wait while Setup updates your system."
                        : "Looking for available updates for your system..."
                case .downloading:
                    statusText = (era == .win95 || era == .win98 || era == .winME)
                        ? "Copying files..."
                        : "Downloading: \(file) (\(rng.nextInt(in: 10...95))%)"
                case .verifying:
                    statusText = "Checking file integrity..."
                case .installing:
                    statusText = (era == .win95 || era == .win98 || era == .winME)
                        ? "Copying: \(path)\(file)"
                        : "Copying to \(path)\(file)..."
                case .configuring:
                    statusText = (era == .win95 || era == .win98 || era == .winME)
                        ? "Updating system settings..."
                        : "Applying configuration changes..."
                case .cleaningUp:
                    statusText = "Removing temporary files..."
                case .restarting:
                    statusText = "Updating system initialization..."
                case .finalizing:
                    statusText = "Setup complete."
                }

                // Step duration calculation with bounded delays
                var stepDuration = (durationSeconds / Double(targetTotalSteps))
                if isStall {
                    stepDuration *= rng.chance(0.5) ? 2.5 : 1.8
                } else if isJump {
                    stepDuration *= 0.4
                } else if isRegression {
                    stepDuration *= 1.6
                }
                stepDuration = min(max(stepDuration, 0.1), 3.5)

                let step = UpdateStep(
                    overallProgress: currentGlobalProgress,
                    stageProgress: frac,
                    currentUpdateIndex: currentItemIndex,
                    totalUpdates: currentTotalUpdates,
                    currentKB: activeKB,
                    currentFilename: file,
                    currentPath: path,
                    message: message,
                    statusText: statusText,
                    stepDuration: stepDuration,
                    isStall: isStall,
                    isJump: isJump,
                    isRegression: isRegression,
                    isRestartPoint: isRestartPoint,
                    rareEvent: activeRareEventForStep
                )

                stageSteps.append(step)
                allSteps.append(step)
            }

            let stage = UpdateStage(
                id: "stage_\(stageIndex)_\(stageKind.rawValue)",
                kind: stageKind,
                title: stageKind.defaultTitle,
                detail: "Stage \(stageIndex + 1) of \(stagesBlueprint.count)",
                startProgress: stageStart,
                endProgress: stageEnd,
                steps: stageSteps
            )
            constructedStages.append(stage)
        }

        // Guarantee final 100% completion step
        if let last = allSteps.last, last.overallProgress < 1.0 {
            let finalStep = UpdateStep(
                overallProgress: 1.0,
                stageProgress: 1.0,
                currentUpdateIndex: currentTotalUpdates,
                totalUpdates: currentTotalUpdates,
                currentKB: updates.last?.kbIdentifier,
                currentFilename: "SETUPX.DLL",
                currentPath: #"C:\WINDOWS\SYSTEM\"#,
                message: (era == .win95 || era == .win98 || era == .winME)
                    ? "Setup has completed updating your system."
                    : "Updates successfully installed.",
                statusText: "System files updated successfully.",
                stepDuration: 1.0
            )
            allSteps.append(finalStep)
        }

        let totalCalculatedDuration = allSteps.reduce(0.0) { $0 + $1.stepDuration }

        let finalOutcome: String
        if era == .win95 || era == .win98 || era == .winME {
            finalOutcome = "Windows has finished updating your system settings."
        } else {
            finalOutcome = "Your system is up to date."
        }

        return UpdateSession(
            seed: effectiveSeed,
            era: era,
            duration: duration,
            personality: personality,
            updates: updates,
            stages: constructedStages,
            allSteps: allSteps,
            rareEventsTriggered: sessionRareEvents,
            finalOutcomeText: finalOutcome,
            totalEstimatedDuration: totalCalculatedDuration
        )
    }
}
