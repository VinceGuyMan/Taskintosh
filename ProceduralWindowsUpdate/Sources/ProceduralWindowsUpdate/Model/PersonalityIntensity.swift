import Foundation

/// Controls the proportion of humor, easter eggs, and Taskintosh flavor vs believable system language.
public enum PersonalityIntensity: String, CaseIterable, Codable, Sendable {
    /// Authentic: 100% period-accurate believable Windows-era UI copy. Zero jokes or easter eggs.
    case authentic
    /// Subtle: Authentic system copy with occasional wholesome notes.
    case subtle
    /// Standard: Traditional believable servicing copy.
    case standard
    /// High vibes / Theatrical: Explicit theatrical mode enabling Taskintosh jokes, meta-updates, and comedy easter eggs.
    case highVibes

    public static let theatrical = PersonalityIntensity.highVibes

    /// Whether comedy, easter eggs, and meta-updates are allowed.
    public var allowsTheatricalEasterEggs: Bool {
        self == .highVibes
    }

    public var weights: (believable: Double, taskintosh: Double, easterEgg: Double) {
        switch self {
        case .authentic:
            return (1.0, 0.0, 0.0)
        case .subtle:
            return (0.95, 0.05, 0.0)
        case .standard:
            return (1.0, 0.0, 0.0)
        case .highVibes:
            return (0.50, 0.35, 0.15)
        }
    }
}
