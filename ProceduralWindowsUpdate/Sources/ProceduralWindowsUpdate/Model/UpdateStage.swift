import Foundation

/// Functional stage of the procedural fake update workflow.
public enum StageKind: String, CaseIterable, Codable, Sendable {
    case checking
    case downloading
    case verifying
    case installing
    case configuring
    case cleaningUp
    case restarting
    case finalizing

    public var defaultTitle: String {
        switch self {
        case .checking: return "Checking for updates..."
        case .downloading: return "Downloading updates..."
        case .verifying: return "Verifying downloaded packages..."
        case .installing: return "Installing updates..."
        case .configuring: return "Configuring system components..."
        case .cleaningUp: return "Cleaning temporary update files..."
        case .restarting: return "Restarting system components..."
        case .finalizing: return "Finalizing update process..."
        }
    }
}

/// A structured stage within an update session containing discrete steps.
public struct UpdateStage: Codable, Sendable, Identifiable {
    public let id: String
    public let kind: StageKind
    public let title: String
    public let detail: String
    public let startProgress: Double
    public let endProgress: Double
    public var steps: [UpdateStep]

    public init(
        id: String = UUID().uuidString,
        kind: StageKind,
        title: String,
        detail: String,
        startProgress: Double,
        endProgress: Double,
        steps: [UpdateStep] = []
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.startProgress = startProgress
        self.endProgress = endProgress
        self.steps = steps
    }
}
