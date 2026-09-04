import Foundation
import Combine

/// Main runtime controller for managing and executing a fake procedural update simulation.
/// Thread-safe, observable, and fully interruptible.
@MainActor
public final class FakeUpdateController: ObservableObject {

    @Published public private(set) var state: UpdateState
    @Published public private(set) var currentSession: UpdateSession?
    @Published public private(set) var activeEra: WindowsEra

    public var onStep: ((UpdateStep, UpdateState) -> Void)?
    public var onCompletion: ((UpdateSession) -> Void)?
    public var onCancel: (() -> Void)?

    private let engine: ProceduralUpdateEngine
    private var stepTask: Task<Void, Never>?
    private var isStepping = false

    public init(
        era: WindowsEra = .win7,
        engine: ProceduralUpdateEngine = ProceduralUpdateEngine()
    ) {
        self.activeEra = era
        self.engine = engine
        self.state = UpdateState.initial(for: era)
    }

    /// Starts a new simulated update session.
    public func start(
        era: WindowsEra? = nil,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .standard,
        seed: UInt64? = nil
    ) {
        cancelCurrentTask()

        let selectedEra = era ?? activeEra
        self.activeEra = selectedEra

        let session = engine.generateSession(
            era: selectedEra,
            duration: duration,
            personality: personality,
            seed: seed
        )
        self.currentSession = session

        // Initialize state
        var newState = UpdateState(
            status: .running,
            overallProgress: 0.0,
            stageProgress: 0.0,
            currentStageIndex: 0,
            currentStepIndex: 0,
            currentUpdateNumber: 1,
            totalUpdateCount: session.updateCount,
            headline: selectedEra.defaultHeadline,
            subheadline: selectedEra.defaultWarningMessage,
            currentMessage: "Initializing update subsystem...",
            currentStatusText: "Connecting to virtual service...",
            activityLog: ["Session started with seed: \(session.seed)"],
            elapsedSeconds: 0.0,
            estimatedSecondsRemaining: session.totalEstimatedDuration,
            isRebooting: false
        )
        if let first = session.allSteps.first {
            applyStep(first, to: &newState, session: session)
        }
        self.state = newState

        runSimulationLoop(session: session, startIndex: 0)
    }

    /// Pauses the current simulation.
    public func pause() {
        guard state.status == .running || state.status == .rebooting else { return }
        cancelCurrentTask()
        state.status = .paused
        state.detailedLog.append("Simulation paused by user.")
    }

    /// Resumes a paused simulation.
    public func resume() {
        guard state.status == .paused, let session = currentSession else { return }
        state.status = .running
        state.detailedLog.append("Simulation resumed.")
        runSimulationLoop(session: session, startIndex: state.currentStepIndex)
    }

    /// Cancels the simulation immediately. Emergency exit guarantee.
    public func cancel() {
        cancelCurrentTask()
        state.status = .cancelled
        state.currentMessage = "Simulation cancelled."
        state.currentStatusText = "Stopped by user."
        state.detailedLog.append("Simulation cancelled via emergency exit.")
        onCancel?()
    }

    /// Resets the controller back to idle.
    public func reset() {
        cancelCurrentTask()
        self.currentSession = nil
        self.state = UpdateState.initial(for: activeEra)
    }

    /// Explicitly overrides state (useful for snapshot testing).
    public func setStateForTesting(_ newState: UpdateState) {
        cancelCurrentTask()
        self.state = newState
    }

    /// Manually advances one step (useful for stepping through or testing).
    public func stepForward() {
        guard let session = currentSession else { return }
        let nextIndex = state.currentStepIndex + 1
        if nextIndex < session.allSteps.count {
            state.currentStepIndex = nextIndex
            applyStep(session.allSteps[nextIndex], to: &state, session: session)
        } else {
            completeSimulation(session: session)
        }
    }

    // MARK: - Private Execution Loop

    private func cancelCurrentTask() {
        stepTask?.cancel()
        stepTask = nil
    }

    private func runSimulationLoop(session: UpdateSession, startIndex: Int) {
        cancelCurrentTask()

        stepTask = Task { [weak self] in
            guard let self = self else { return }

            for i in startIndex..<session.allSteps.count {
                if Task.isCancelled { break }

                let step = session.allSteps[i]
                let durationMs = UInt64(max(0.05, step.stepDuration) * 1_000_000_000)

                // Apply step to published state on main thread
                self.state.currentStepIndex = i
                self.applyStep(step, to: &self.state, session: session)
                self.onStep?(step, self.state)

                // Handle simulated reboot if triggered
                if step.isRestartPoint {
                    self.state.isRebooting = true
                    self.state.status = .rebooting
                } else if self.state.isRebooting && !step.isRestartPoint {
                    self.state.isRebooting = false
                    self.state.status = .running
                }

                // Sleep for the step's bounded duration
                do {
                    try await Task.sleep(nanoseconds: durationMs)
                } catch {
                    // Task cancelled
                    break
                }
            }

            if !Task.isCancelled {
                self.completeSimulation(session: session)
            }
        }
    }

    private func applyStep(_ step: UpdateStep, to targetState: inout UpdateState, session: UpdateSession) {
        targetState.overallProgress = step.overallProgress
        targetState.stageProgress = step.stageProgress
        targetState.currentUpdateNumber = step.currentUpdateIndex
        targetState.totalUpdateCount = step.totalUpdates
        targetState.currentMessage = step.message
        targetState.currentStatusText = step.statusText
        targetState.currentFile = step.currentFilename
        targetState.currentPath = step.currentPath
        targetState.currentKB = step.currentKB
        targetState.activeRareEvent = step.rareEvent

        targetState.elapsedSeconds += step.stepDuration
        targetState.estimatedSecondsRemaining = max(0.0, session.totalEstimatedDuration - targetState.elapsedSeconds)

        // Append log line
        let logLine = "[\(targetState.percentageInt)%] \(step.message)"
        if targetState.activityLog.last != logLine {
            targetState.activityLog.append(logLine)
            if targetState.activityLog.count > 50 {
                targetState.activityLog.removeFirst()
            }
        }
    }

    private func completeSimulation(session: UpdateSession) {
        state.status = .completed
        state.overallProgress = 1.0
        state.stageProgress = 1.0
        state.currentMessage = session.finalOutcomeText
        state.currentStatusText = "Update complete. Your system is up to date."
        state.detailedLog.append("Session completed successfully.")
        onCompletion?(session)
    }
}
