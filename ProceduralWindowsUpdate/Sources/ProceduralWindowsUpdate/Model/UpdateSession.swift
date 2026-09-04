import Foundation

/// Blueprint of a complete deterministic update session generated from a seed.
public struct UpdateSession: Codable, Sendable, Identifiable {
    public let id: UUID
    public let seed: UInt64
    public let era: WindowsEra
    public let duration: UpdateDuration
    public let personality: PersonalityIntensity
    public let updates: [FakeUpdateItem]
    public let stages: [UpdateStage]
    public let allSteps: [UpdateStep]
    public let rareEventsTriggered: [RareEvent]
    public let finalOutcomeText: String
    public let totalEstimatedDuration: TimeInterval

    public var updateCount: Int {
        updates.count
    }

    public init(
        id: UUID = UUID(),
        seed: UInt64,
        era: WindowsEra,
        duration: UpdateDuration = .normal,
        personality: PersonalityIntensity = .standard,
        updates: [FakeUpdateItem],
        stages: [UpdateStage],
        allSteps: [UpdateStep],
        rareEventsTriggered: [RareEvent] = [],
        finalOutcomeText: String = "Your system is up to date.",
        totalEstimatedDuration: TimeInterval = 28.0
    ) {
        self.id = id
        self.seed = seed
        self.era = era
        self.duration = duration
        self.personality = personality
        self.updates = updates
        self.stages = stages
        self.allSteps = allSteps
        self.rareEventsTriggered = rareEventsTriggered
        self.finalOutcomeText = finalOutcomeText
        self.totalEstimatedDuration = totalEstimatedDuration
    }
}
