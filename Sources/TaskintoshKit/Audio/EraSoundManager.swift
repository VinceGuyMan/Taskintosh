import Foundation
import AVFoundation
import AppKit

/// Represents an individual procedural synthesizer tone for mock startup audio.
public struct ProceduralAudioNote: Sendable {
    public let frequency: Double
    public let startTime: Double
    public let duration: Double
    public let volume: Double
    public let harmonics: [Double]
    public let attackDuration: Double
    public let decayConstant: Double

    public init(
        frequency: Double,
        startTime: Double,
        duration: Double,
        volume: Double = 0.5,
        harmonics: [Double] = [1.0, 0.3, 0.1],
        attackDuration: Double = 0.08,
        decayConstant: Double = 1.8
    ) {
        self.frequency = frequency
        self.startTime = startTime
        self.duration = duration
        self.volume = volume
        self.harmonics = harmonics
        self.attackDuration = attackDuration
        self.decayConstant = decayConstant
    }
}

/// Synthesizes clean-room procedural PCM audio into valid in-memory WAV files.
public final class ProceduralSoundSynthesizer {

    /// Synthesizes an array of notes into a RIFF WAVE format byte buffer.
    public static func synthesizeWAV(
        notes: [ProceduralAudioNote],
        sampleRate: Int = 44100
    ) -> Data {
        let maxEndTime = notes.map { $0.startTime + $0.duration }.max() ?? 1.0
        let totalSamples = max(1, Int(ceil(Double(sampleRate) * maxEndTime)))
        var samples = [Float](repeating: 0.0, count: totalSamples)

        for note in notes {
            let startIndex = Int(note.startTime * Double(sampleRate))
            let noteSamples = Int(note.duration * Double(sampleRate))
            let endIndex = min(totalSamples, startIndex + noteSamples)

            for i in startIndex..<endIndex {
                let t = Double(i - startIndex) / Double(sampleRate)

                // Attack envelope: linear ramp
                let attack = note.attackDuration > 0 ? min(1.0, t / note.attackDuration) : 1.0
                // Exponential decay envelope
                let decay = exp(-t * note.decayConstant)
                let envelope = Float(attack * decay * note.volume)

                // Additive harmonics synthesis
                var sampleValue: Float = 0.0
                for (hIndex, hWeight) in note.harmonics.enumerated() {
                    let harmonicMultiplier = Double(hIndex + 1)
                    let phase = 2.0 * Double.pi * note.frequency * harmonicMultiplier * t
                    sampleValue += Float(hWeight * sin(phase))
                }

                samples[i] += sampleValue * envelope
            }
        }

        // Normalize / soft-limit to avoid clipping
        var maxPeak: Float = 0.0
        for s in samples {
            let absS = abs(s)
            if absS > maxPeak { maxPeak = absS }
        }
        let gain: Float = maxPeak > 0.95 ? (0.95 / maxPeak) : 0.85

        // Construct 16-bit PCM RIFF WAVE
        var wavData = Data()

        let subchunk2Size = UInt32(totalSamples * 2) // 16-bit = 2 bytes per sample
        let chunkSize = UInt32(36 + subchunk2Size)

        wavData.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSizeLE = chunkSize.littleEndian
        wavData.append(Data(bytes: &chunkSizeLE, count: 4))
        wavData.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        // "fmt " subchunk
        wavData.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size: UInt32 = 16
        wavData.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: UInt16 = 1 // PCM
        wavData.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: UInt16 = 1 // Mono
        wavData.append(Data(bytes: &numChannels, count: 2))
        var sRate = UInt32(sampleRate).littleEndian
        wavData.append(Data(bytes: &sRate, count: 4))
        let byteRate = UInt32(sampleRate * 2).littleEndian
        var bRate = byteRate
        wavData.append(Data(bytes: &bRate, count: 4))
        var blockAlign: UInt16 = 2
        wavData.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: UInt16 = 16
        wavData.append(Data(bytes: &bitsPerSample, count: 2))

        // "data" subchunk
        wavData.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var s2Size = subchunk2Size.littleEndian
        wavData.append(Data(bytes: &s2Size, count: 4))

        // Write 16-bit PCM samples
        for s in samples {
            let clamped = max(-1.0, min(1.0, s * gain))
            var intSample = Int16(clamped * 32767.0).littleEndian
            wavData.append(Data(bytes: &intSample, count: 2))
        }

        return wavData
    }
}

/// Central manager for generation startup audio synthesis and playback.
@MainActor
public final class EraSoundManager: NSObject, AVAudioPlayerDelegate {
    public static let shared = EraSoundManager()

    nonisolated public static let preferenceKey = "TaskbarPlayStartupSound"

    /// Whether startup sounds are enabled upon switching generations.
    public var isSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Self.preferenceKey) == nil {
                return true // Default enabled
            }
            return UserDefaults.standard.bool(forKey: Self.preferenceKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.preferenceKey)
        }
    }

    private var activePlayer: AVAudioPlayer?
    private var cachedSoundData: [String: Data] = [:]

    override public init() {
        super.init()
    }

    /// Plays the startup sound for the specified era package.
    public func playStartupSound(for era: EraPackage, ignoreMute: Bool = false) {
        if !ignoreMute && !isSoundEnabled { return }

        // 1. Check if the era package provides an authentic custom audio asset
        if let customAudioURL = findCustomStartupAudio(in: era) {
            playAudio(from: customAudioURL)
            return
        }

        // 2. Otherwise synthesize/play the clean-room mock startup chime
        let soundData = soundData(for: era.manifest.id)
        playAudio(fromData: soundData)
    }

    /// Checks if a custom startup sound file exists within an Era package.
    public func findCustomStartupAudio(in era: EraPackage) -> URL? {
        guard let rootURL = era.rootURL else { return nil }
        let fileManager = FileManager.default
        let candidates = ["startup.wav", "startup.mp3", "startup.aiff", "startup.m4a"]
        for candidate in candidates {
            let direct = rootURL.appendingPathComponent(candidate)
            if fileManager.fileExists(atPath: direct.path) {
                return direct
            }
            let inAssets = rootURL.appendingPathComponent("assets").appendingPathComponent(candidate)
            if fileManager.fileExists(atPath: inAssets.path) {
                return inAssets
            }
        }
        return nil
    }

    /// Retrieves or synthesizes the clean-room WAV audio data for the era.
    public func soundData(for eraID: String) -> Data {
        let key = eraID.lowercased()
        if let cached = cachedSoundData[key] {
            return cached
        }
        let notes = Self.notes(for: eraID)
        let data = ProceduralSoundSynthesizer.synthesizeWAV(notes: notes)
        cachedSoundData[key] = data
        return data
    }

    /// Plays synthesized audio data using AVAudioPlayer.
    public func playAudio(fromData data: Data) {
        do {
            activePlayer?.stop()
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.activePlayer = player
        } catch {
            print("⚠️ [EraSoundManager] Audio playback failed: \(error)")
        }
    }

    /// Plays audio from a local file URL.
    public func playAudio(from url: URL) {
        do {
            activePlayer?.stop()
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.activePlayer = player
        } catch {
            print("⚠️ [EraSoundManager] File audio playback failed: \(error)")
        }
    }

    public func stopAudio() {
        activePlayer?.stop()
        activePlayer = nil
    }

    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if self.activePlayer === player {
                self.activePlayer = nil
            }
        }
    }

    // MARK: - Era Chord Voicings & Progressions

    /// Clean-room musical progressions evocative of each operating system era.
    nonisolated public static func notes(for eraID: String) -> [ProceduralAudioNote] {
        let lower = eraID.lowercased()

        if lower.contains("95") {
            // Windows 95: Floating ambient pentatonic chord swell
            return [
                ProceduralAudioNote(frequency: 138.59, startTime: 0.0, duration: 3.2, volume: 0.45, harmonics: [1.0, 0.4, 0.15], attackDuration: 0.35, decayConstant: 0.8), // Db3
                ProceduralAudioNote(frequency: 207.65, startTime: 0.1, duration: 3.0, volume: 0.50, harmonics: [1.0, 0.35, 0.2], attackDuration: 0.30, decayConstant: 0.85), // Ab3
                ProceduralAudioNote(frequency: 277.18, startTime: 0.3, duration: 2.8, volume: 0.55, harmonics: [1.0, 0.3, 0.1], attackDuration: 0.25, decayConstant: 0.9), // Db4
                ProceduralAudioNote(frequency: 349.23, startTime: 0.6, duration: 2.5, volume: 0.55, harmonics: [1.0, 0.25, 0.1], attackDuration: 0.25, decayConstant: 0.95), // F4
                ProceduralAudioNote(frequency: 415.30, startTime: 0.9, duration: 2.2, volume: 0.50, harmonics: [1.0, 0.2, 0.05], attackDuration: 0.20, decayConstant: 1.0), // Ab4
                ProceduralAudioNote(frequency: 523.25, startTime: 1.2, duration: 1.9, volume: 0.40, harmonics: [1.0, 0.15, 0.05], attackDuration: 0.20, decayConstant: 1.1), // C5
                ProceduralAudioNote(frequency: 698.46, startTime: 1.5, duration: 1.6, volume: 0.30, harmonics: [1.0, 0.1], attackDuration: 0.20, decayConstant: 1.2) // F5
            ]
        } else if lower.contains("xp") {
            // Windows XP: Cheerful 4-note ascending bell chime
            return [
                ProceduralAudioNote(frequency: 311.13, startTime: 0.0, duration: 0.7, volume: 0.65, harmonics: [1.0, 0.5, 0.25, 0.1], attackDuration: 0.04, decayConstant: 2.5), // Eb4
                ProceduralAudioNote(frequency: 466.16, startTime: 0.24, duration: 0.7, volume: 0.70, harmonics: [1.0, 0.5, 0.2, 0.1], attackDuration: 0.04, decayConstant: 2.4), // Bb4
                ProceduralAudioNote(frequency: 415.30, startTime: 0.52, duration: 0.7, volume: 0.68, harmonics: [1.0, 0.45, 0.2, 0.1], attackDuration: 0.04, decayConstant: 2.3), // Ab4
                ProceduralAudioNote(frequency: 622.25, startTime: 0.82, duration: 1.5, volume: 0.80, harmonics: [1.0, 0.4, 0.2, 0.05], attackDuration: 0.04, decayConstant: 1.6), // Eb5
                ProceduralAudioNote(frequency: 155.56, startTime: 0.82, duration: 1.5, volume: 0.45, harmonics: [1.0, 0.3], attackDuration: 0.15, decayConstant: 1.5) // Eb3
            ]
        } else if lower.contains("7") {
            // Windows 7: Translucent Aero Glass 4-note marimba
            return [
                ProceduralAudioNote(frequency: 523.25, startTime: 0.0, duration: 0.6, volume: 0.60, harmonics: [1.0, 0.6, 0.1], attackDuration: 0.02, decayConstant: 3.5), // C5
                ProceduralAudioNote(frequency: 783.99, startTime: 0.18, duration: 0.6, volume: 0.65, harmonics: [1.0, 0.55, 0.1], attackDuration: 0.02, decayConstant: 3.2), // G5
                ProceduralAudioNote(frequency: 659.25, startTime: 0.36, duration: 0.7, volume: 0.68, harmonics: [1.0, 0.5, 0.1], attackDuration: 0.02, decayConstant: 3.0), // E5
                ProceduralAudioNote(frequency: 1046.50, startTime: 0.56, duration: 1.4, volume: 0.75, harmonics: [1.0, 0.4, 0.05], attackDuration: 0.02, decayConstant: 2.0), // C6
                ProceduralAudioNote(frequency: 261.63, startTime: 0.56, duration: 1.4, volume: 0.40, harmonics: [1.0, 0.2], attackDuration: 0.08, decayConstant: 2.0) // C4
            ]
        } else if lower.contains("8") {
            // Windows 8: Minimalist two-tone digital pulse
            return [
                ProceduralAudioNote(frequency: 698.46, startTime: 0.0, duration: 0.4, volume: 0.65, harmonics: [1.0, 0.2], attackDuration: 0.03, decayConstant: 4.0), // F5
                ProceduralAudioNote(frequency: 1046.50, startTime: 0.18, duration: 1.0, volume: 0.72, harmonics: [1.0, 0.25], attackDuration: 0.03, decayConstant: 2.5) // C6
            ]
        } else if lower.contains("10") {
            // Windows 10: Atmospheric major triad notification swell
            return [
                ProceduralAudioNote(frequency: 293.66, startTime: 0.0, duration: 1.7, volume: 0.50, harmonics: [1.0, 0.35, 0.1], attackDuration: 0.12, decayConstant: 1.8), // D4
                ProceduralAudioNote(frequency: 440.00, startTime: 0.20, duration: 1.5, volume: 0.60, harmonics: [1.0, 0.3, 0.1], attackDuration: 0.10, decayConstant: 1.8), // A4
                ProceduralAudioNote(frequency: 739.99, startTime: 0.42, duration: 1.3, volume: 0.68, harmonics: [1.0, 0.2, 0.05], attackDuration: 0.08, decayConstant: 1.7) // F#5
            ]
        } else if lower.contains("11") {
            // Windows 11: Ethereal Fluent acoustic breath chord
            return [
                ProceduralAudioNote(frequency: 246.94, startTime: 0.0, duration: 2.2, volume: 0.45, harmonics: [1.0, 0.4, 0.1], attackDuration: 0.25, decayConstant: 1.2), // B3
                ProceduralAudioNote(frequency: 369.99, startTime: 0.16, duration: 2.0, volume: 0.55, harmonics: [1.0, 0.35, 0.05], attackDuration: 0.20, decayConstant: 1.3), // F#4
                ProceduralAudioNote(frequency: 622.25, startTime: 0.32, duration: 1.8, volume: 0.60, harmonics: [1.0, 0.3, 0.05], attackDuration: 0.15, decayConstant: 1.4), // D#5
                ProceduralAudioNote(frequency: 830.61, startTime: 0.50, duration: 1.6, volume: 0.55, harmonics: [1.0, 0.2, 0.05], attackDuration: 0.12, decayConstant: 1.5) // G#5
            ]
        } else {
            // Generic retro era fallback
            return [
                ProceduralAudioNote(frequency: 523.25, startTime: 0.0, duration: 0.5, volume: 0.6, harmonics: [1.0, 0.3], attackDuration: 0.03, decayConstant: 3.0),
                ProceduralAudioNote(frequency: 783.99, startTime: 0.2, duration: 1.0, volume: 0.7, harmonics: [1.0, 0.3], attackDuration: 0.03, decayConstant: 2.0)
            ]
        }
    }
}
