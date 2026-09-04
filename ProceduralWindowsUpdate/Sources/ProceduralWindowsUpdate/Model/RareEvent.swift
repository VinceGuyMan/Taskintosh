import Foundation

/// Rare procedural events and easter eggs that may trigger during a theatrical update session.
public enum RareEvent: String, CaseIterable, Codable, Sendable, Identifiable {
    /// CANON LINE: Must be preserved verbatim
    case canonicalMetaUpdate = "canonical_meta_update"
    case updateFoundForWindowsUpdate = "update_found_for_wu"
    case servicePackVibes = "service_pack_vibes"
    case taskintoshCompatibilityRollup = "taskintosh_rollup"
    case fakeGlitchAndRecovery = "glitch_and_recovery"
    case fakeRebootPhase = "fake_reboot"
    case cleaningUpOldVibes = "cleaning_old_vibes"
    case midSessionCountIncrease = "count_increase"
    case crossEraPatch = "cross_era_patch"
    case clippyEmploymentCheck = "clippy_check"
    case unnecessaryOptimism = "unnecessary_optimism"
    case restoreStartMenuDignity = "restore_dignity"
    case suspiciouslyHelpfulDll = "suspicious_dll"
    case deleteTempPsd = "delete_psd"
    case teachLegacyShellAi = "teach_ai"
    case win7EmotionalSupport = "emotional_support"
    case wholesomeAffirmation = "wholesome_affirmation"

    public var id: String { rawValue }

    /// Canonical or primary phrase associated with this rare event
    public var primaryMessage: String {
        switch self {
        case .canonicalMetaUpdate:
            return "Updating Windows Update so Windows Update can update Windows Update"
        case .updateFoundForWindowsUpdate:
            return "Windows Update found an update for Windows Update"
        case .servicePackVibes:
            return "Applying Service Pack: Vibes (Build 420.77)"
        case .taskintoshCompatibilityRollup:
            return "Installing Taskintosh Mac ↔ Windows Cultural Exchange Rollup"
        case .fakeGlitchAndRecovery:
            return "Encountered non-fatal error 0x8024402F. Engaging automatic vibecache fallback... Recovered!"
        case .fakeRebootPhase:
            return "Restarting Taskintosh virtual subsystem to apply core updates..."
        case .cleaningUpOldVibes:
            return "Cleaning up old vibes..."
        case .midSessionCountIncrease:
            return "Checking dependencies... 3 additional updates discovered!"
        case .crossEraPatch:
            return "Installing Windows 95 Hotfix for Windows 11 (KB951995)"
        case .clippyEmploymentCheck:
            return "Checking whether Clippy is still employed"
        case .unnecessaryOptimism:
            return "Downloading unnecessary optimism"
        case .restoreStartMenuDignity:
            return "Restoring Start menu dignity"
        case .suspiciouslyHelpfulDll:
            return "Installing one suspiciously helpful DLL"
        case .deleteTempPsd:
            return "Deleting definitely_not_temp_final_v6.psd"
        case .teachLegacyShellAi:
            return "Teaching legacy shell about AI agents"
        case .win7EmotionalSupport:
            return "Installing Windows 7 emotional support package"
        case .wholesomeAffirmation:
            return "Verifying everything is going to be okay"
        }
    }

    /// Associated simulated file if applicable
    public var associatedFilename: String? {
        switch self {
        case .canonicalMetaUpdate, .updateFoundForWindowsUpdate:
            return "wuauclt_updater.dll"
        case .servicePackVibes:
            return "vibes_sp1.cab"
        case .taskintoshCompatibilityRollup:
            return "taskintosh_rollup.msu"
        case .fakeGlitchAndRecovery:
            return "retry_recovery.sys"
        case .fakeRebootPhase:
            return "vibrst.exe"
        case .cleaningUpOldVibes:
            return "vibe_cleanup.tmp"
        case .midSessionCountIncrease:
            return "prerequisite_pack.cab"
        case .crossEraPatch:
            return "win95_compat_shim.vxd"
        case .clippyEmploymentCheck:
            return "clippy_residual_memory.sys"
        case .unnecessaryOptimism:
            return "optimism.cab"
        case .restoreStartMenuDignity:
            return "start_dignity.dll"
        case .suspiciouslyHelpfulDll:
            return "suspiciously_helpful.dll"
        case .deleteTempPsd:
            return "definitely_not_temp_final_v6.psd"
        case .teachLegacyShellAi:
            return "agent_registry.db"
        case .win7EmotionalSupport:
            return "emotional_support.pkg"
        case .wholesomeAffirmation:
            return "patience.dll"
        }
    }

    /// Relative weight / rarity (lower = rarer)
    public var rarityWeight: Double {
        switch self {
        case .canonicalMetaUpdate:
            return 3.0 // Special milestone, guaranteed seed preset available
        case .fakeGlitchAndRecovery:
            return 2.5
        case .midSessionCountIncrease:
            return 2.5
        case .servicePackVibes:
            return 2.0
        case .taskintoshCompatibilityRollup:
            return 2.0
        case .cleaningUpOldVibes:
            return 2.0
        case .clippyEmploymentCheck:
            return 1.5
        case .restoreStartMenuDignity:
            return 1.5
        case .wholesomeAffirmation:
            return 2.0
        default:
            return 1.0
        }
    }
}
