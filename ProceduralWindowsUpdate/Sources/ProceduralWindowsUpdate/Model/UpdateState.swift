import Foundation

/// Status of the simulation run.
public enum SimulationStatus: String, Codable, Sendable {
    case idle
    case running
    case paused
    case rebooting
    case cancelled
    case completed

    public var isTerminal: Bool {
        self == .cancelled || self == .completed
    }

    public var isActive: Bool {
        self == .running || self == .rebooting
    }
}

/// The runtime observable state of an active or completed fake update session.
public struct UpdateState: Codable, Sendable {
    public var status: SimulationStatus
    public var overallProgress: Double
    public var stageProgress: Double
    public var currentStageIndex: Int
    public var currentStepIndex: Int
    public var currentUpdateNumber: Int
    public var totalUpdateCount: Int
    public var headline: String
    public var subheadline: String
    public var currentMessage: String
    public var currentStatusText: String
    public var currentFile: String?
    public var currentPath: String?
    public var currentKB: String?
    public var activeRareEvent: RareEvent?
    public var activityLog: [String]
    public var detailedLog: [String] {
        get { activityLog }
        set { activityLog = newValue }
    }
    public var elapsedSeconds: TimeInterval
    public var estimatedSecondsRemaining: TimeInterval
    public var isRebooting: Bool

    public init(
        status: SimulationStatus = .idle,
        overallProgress: Double = 0.0,
        stageProgress: Double = 0.0,
        currentStageIndex: Int = 0,
        currentStepIndex: Int = 0,
        currentUpdateNumber: Int = 1,
        totalUpdateCount: Int = 1,
        headline: String = "Windows Update",
        subheadline: String = "",
        currentMessage: String = "Ready to start",
        currentStatusText: String = "",
        currentFile: String? = nil,
        currentPath: String? = nil,
        currentKB: String? = nil,
        activeRareEvent: RareEvent? = nil,
        activityLog: [String] = [],
        elapsedSeconds: TimeInterval = 0.0,
        estimatedSecondsRemaining: TimeInterval = 0.0,
        isRebooting: Bool = false
    ) {
        self.status = status
        self.overallProgress = min(max(overallProgress, 0.0), 1.0)
        self.stageProgress = min(max(stageProgress, 0.0), 1.0)
        self.currentStageIndex = currentStageIndex
        self.currentStepIndex = currentStepIndex
        self.currentUpdateNumber = currentUpdateNumber
        self.totalUpdateCount = totalUpdateCount
        self.headline = headline
        self.subheadline = subheadline
        self.currentMessage = currentMessage
        self.currentStatusText = currentStatusText
        self.currentFile = currentFile
        self.currentPath = currentPath
        self.currentKB = currentKB
        self.activeRareEvent = activeRareEvent
        self.activityLog = activityLog
        self.elapsedSeconds = elapsedSeconds
        self.estimatedSecondsRemaining = max(0.0, estimatedSecondsRemaining)
        self.isRebooting = isRebooting
    }

    /// Progress formatted as integer percentage (0 to 100)
    public var percentageInt: Int {
        Int(overallProgress * 100)
    }

    /// Default idle state for a given era
    public static func initial(for era: WindowsEra) -> UpdateState {
        UpdateState(
            status: .idle,
            headline: era.defaultHeadline,
            subheadline: era.defaultWarningMessage,
            currentMessage: "Checking for updates..."
        )
    }
}
