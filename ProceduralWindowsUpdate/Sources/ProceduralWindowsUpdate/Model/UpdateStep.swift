import Foundation

/// A single granular procedural step in the theatrical update simulation.
public struct UpdateStep: Codable, Sendable, Identifiable {
    public let id: String
    public let overallProgress: Double
    public let stageProgress: Double
    public let currentUpdateIndex: Int
    public let totalUpdates: Int
    public let currentKB: String?
    public let currentFilename: String?
    public let currentPath: String?
    public let message: String
    public let statusText: String
    public let stepDuration: TimeInterval
    public let isStall: Bool
    public let isJump: Bool
    public let isRegression: Bool
    public let isRestartPoint: Bool
    public let rareEvent: RareEvent?

    public init(
        id: String = UUID().uuidString,
        overallProgress: Double,
        stageProgress: Double,
        currentUpdateIndex: Int,
        totalUpdates: Int,
        currentKB: String? = nil,
        currentFilename: String? = nil,
        currentPath: String? = nil,
        message: String,
        statusText: String = "",
        stepDuration: TimeInterval = 0.35,
        isStall: Bool = false,
        isJump: Bool = false,
        isRegression: Bool = false,
        isRestartPoint: Bool = false,
        rareEvent: RareEvent? = nil
    ) {
        self.id = id
        self.overallProgress = min(max(overallProgress, 0.0), 1.0)
        self.stageProgress = min(max(stageProgress, 0.0), 1.0)
        self.currentUpdateIndex = max(1, currentUpdateIndex)
        self.totalUpdates = max(1, totalUpdates)
        self.currentKB = currentKB
        self.currentFilename = currentFilename
        self.currentPath = currentPath
        self.message = message
        self.statusText = statusText
        self.stepDuration = max(0.05, stepDuration)
        self.isStall = isStall
        self.isJump = isJump
        self.isRegression = isRegression
        self.isRestartPoint = isRestartPoint
        self.rareEvent = rareEvent
    }
}
