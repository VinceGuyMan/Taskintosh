import Foundation

/// Unified content provider that blends believable system copy, Taskintosh personality,
/// and rare absurd easter eggs according to configured personality weights.
public struct ContentPools {

    public enum ContentFlavor: Sendable {
        case believable
        case taskintosh
        case easterEgg
        case wholesome
    }

    /// Resolves the content flavor based on personality weights and random roll.
    /// Default mode strictly returns `.believable` to ensure historical authenticity.
    public static func pickFlavor(
        intensity: PersonalityIntensity,
        rng: inout SplitMix64
    ) -> ContentFlavor {
        guard intensity.allowsTheatricalEasterEggs else {
            return .believable
        }

        let weights = intensity.weights
        let roll = rng.nextDouble()

        if roll < weights.believable {
            return .believable
        } else if roll < weights.believable + weights.taskintosh {
            return rng.chance(0.35) ? .wholesome : .taskintosh
        } else {
            return .easterEgg
        }
    }

    /// Selects a contextual step message
    public static func pickMessage(
        era: WindowsEra,
        stage: StageKind,
        intensity: PersonalityIntensity,
        rareEvent: RareEvent?,
        rng: inout SplitMix64
    ) -> String {
        if intensity.allowsTheatricalEasterEggs, let event = rareEvent {
            return event.primaryMessage
        }

        let flavor = pickFlavor(intensity: intensity, rng: &rng)

        switch flavor {
        case .believable:
            let options = SystemFilenames.believableMessages(for: era, stage: stage)
            return rng.choose(from: options) ?? stage.defaultTitle

        case .taskintosh:
            return rng.choose(from: TaskintoshContent.messages) ?? "Optimizing Taskintosh compatibility bridge"

        case .wholesome:
            return rng.choose(from: TaskintoshContent.wholesomeMessages) ?? "Preserving user creativity..."

        case .easterEgg:
            let easterEggOptions = [
                "Updating Windows Update so Windows Update can update Windows Update",
                "Checking whether Clippy is still employed",
                "Downloading unnecessary optimism",
                "Restoring Start menu dignity",
                "Installing one suspiciously helpful DLL",
                "Deleting definitely_not_temp_final_v6.psd",
                "Teaching legacy shell about AI agents",
                "Installing Windows 7 emotional support package",
                "Cleaning up old vibes...",
                "Windows Update found an update for Windows Update",
                "Auditing nostalgic sound effects for emotional fidelity"
            ]
            return rng.choose(from: easterEggOptions) ?? "Updating Windows Update so Windows Update can update Windows Update"
        }
    }

    /// Selects a filename and directory path for the active operation
    public static func pickFileAndPath(
        era: WindowsEra,
        intensity: PersonalityIntensity = .authentic,
        rareEvent: RareEvent?,
        rng: inout SplitMix64
    ) -> (file: String, path: String) {
        if intensity.allowsTheatricalEasterEggs, let event = rareEvent, let eventFile = event.associatedFilename {
            let path = rng.choose(from: SystemFilenames.paths(for: era)) ?? #"C:\WINDOWS\System32\"#
            return (eventFile, path)
        }

        let isTaskintoshRoll = intensity.allowsTheatricalEasterEggs && rng.chance(0.25)
        if isTaskintoshRoll {
            let file = rng.choose(from: TaskintoshContent.filenames) ?? "vibe_cache.index"
            let path = rng.choose(from: TaskintoshContent.paths) ?? #"C:\ProgramData\Taskintosh\Vibes\"#
            return (file, path)
        } else {
            let file = rng.choose(from: SystemFilenames.files(for: era)) ?? "SHELL32.DLL"
            let path = rng.choose(from: SystemFilenames.paths(for: era)) ?? #"C:\WINDOWS\SYSTEM\"#
            return (file, path)
        }
    }
}
