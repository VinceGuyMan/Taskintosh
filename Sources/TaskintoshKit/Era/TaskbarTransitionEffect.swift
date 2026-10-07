import Foundation
import AppKit

/// A suite of visual transitions for moving between taskbar generations.
public enum TaskbarTransitionEffect: String, CaseIterable, Sendable {
    case crossfade = "crossfade"
    case slidePush = "slidePush"
    case curtainWipe = "curtainWipe"
    case crtMorph = "crtMorph"
    case glassBloom = "glassBloom"
    case timeWarp = "timeWarp"

    public var displayName: String {
        switch self {
        case .crossfade: return "Smooth Crossfade"
        case .slidePush: return "Slide & Push"
        case .curtainWipe: return "Scanline Curtain Wipe"
        case .crtMorph: return "Retro CRT Morph"
        case .glassBloom: return "Aero Glass Bloom"
        case .timeWarp: return "Time Warp Dither"
        }
    }

    public var subtitle: String {
        switch self {
        case .crossfade: return "Silky smooth opacity dissolve between generations"
        case .slidePush: return "Physical generation push with dimensional seam"
        case .curtainWipe: return "CRT electron beam horizontal wipe with neon glow"
        case .crtMorph: return "Nostalgic cathode-ray tube phosphor beam collapse & expand"
        case .glassBloom: return "Luminous frosted glass glow solidifying into focus"
        case .timeWarp: return "Digital matrix block dissolution with retro scanlines"
        }
    }

    public static let preferenceKey = "TaskbarTransitionEffect"

    /// Gets or sets the preferred effect in UserDefaults.
    public static var preferredEffect: TaskbarTransitionEffect {
        get {
            if let raw = UserDefaults.standard.string(forKey: preferenceKey) {
                if raw == "random" {
                    return TaskbarTransitionEffect.allCases.randomElement() ?? .crossfade
                }
                if let effect = TaskbarTransitionEffect(rawValue: raw) {
                    return effect
                }
            }
            return .crossfade
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: preferenceKey)
        }
    }

    /// Whether random cycling mode is enabled across era switches.
    public static var isCycleMode: Bool {
        get {
            return UserDefaults.standard.string(forKey: preferenceKey) == "random"
        }
        set {
            if newValue {
                UserDefaults.standard.set("random", forKey: preferenceKey)
            } else {
                UserDefaults.standard.set(TaskbarTransitionEffect.crossfade.rawValue, forKey: preferenceKey)
            }
        }
    }
}
