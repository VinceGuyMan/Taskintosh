import Foundation

/// Defines the overall target duration and pacing profile of the fake update session.
public enum UpdateDuration: Equatable, Sendable, Codable, Hashable {
    /// Quick ~12 second demo/preview session
    case short
    /// Standard ~28 second authentic feeling session
    case normal
    /// Long theatrical ~65 second immersive session
    case theatrical
    /// User-specified custom duration in seconds
    case custom(seconds: TimeInterval)

    /// Target total duration in wall-clock seconds
    public var targetDurationSeconds: TimeInterval {
        switch self {
        case .short: return 12.0
        case .normal: return 28.0
        case .theatrical: return 65.0
        case .custom(let seconds): return max(4.0, seconds)
        }
    }

    /// Display title
    public var displayName: String {
        switch self {
        case .short: return "Short (~12s)"
        case .normal: return "Normal (~28s)"
        case .theatrical: return "Theatrical (~65s)"
        case .custom(let seconds): return String(format: "Custom (%.1fs)", seconds)
        }
    }

    /// Base step count multiplier
    public var stepCountMultiplier: Double {
        switch self {
        case .short: return 0.6
        case .normal: return 1.0
        case .theatrical: return 2.2
        case .custom(let seconds): return max(0.4, seconds / 28.0)
        }
    }
}
