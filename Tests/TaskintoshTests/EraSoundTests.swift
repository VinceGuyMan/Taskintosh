import XCTest
import AVFoundation
@testable import TaskintoshKit

final class EraSoundTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: EraSoundManager.preferenceKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: EraSoundManager.preferenceKey)
        super.tearDown()
    }

    func testWAVGenerationFormatAndHeader() {
        let notes = [
            ProceduralAudioNote(frequency: 440.0, startTime: 0.0, duration: 0.5, volume: 0.5)
        ]
        let wavData = ProceduralSoundSynthesizer.synthesizeWAV(notes: notes, sampleRate: 44100)

        // 1. Minimum size: 44-byte header + at least 1 sample (2 bytes)
        XCTAssertGreaterThanOrEqual(wavData.count, 46)

        // 2. Validate RIFF and WAVE magic signatures
        let riffHeader = String(data: wavData.subdata(in: 0..<4), encoding: .ascii)
        XCTAssertEqual(riffHeader, "RIFF")

        let waveHeader = String(data: wavData.subdata(in: 8..<12), encoding: .ascii)
        XCTAssertEqual(waveHeader, "WAVE")

        let fmtHeader = String(data: wavData.subdata(in: 12..<16), encoding: .ascii)
        XCTAssertEqual(fmtHeader, "fmt ")

        let dataHeader = String(data: wavData.subdata(in: 36..<40), encoding: .ascii)
        XCTAssertEqual(dataHeader, "data")

        // 3. Audio format should be 1 (PCM) and 1 channel
        let audioFormat = wavData.subdata(in: 20..<22).withUnsafeBytes { $0.load(as: UInt16.self) }
        XCTAssertEqual(audioFormat, 1)

        let numChannels = wavData.subdata(in: 22..<24).withUnsafeBytes { $0.load(as: UInt16.self) }
        XCTAssertEqual(numChannels, 1)

        let sampleRate = wavData.subdata(in: 24..<28).withUnsafeBytes { $0.load(as: UInt32.self) }
        XCTAssertEqual(sampleRate, 44100)

        let bitsPerSample = wavData.subdata(in: 34..<36).withUnsafeBytes { $0.load(as: UInt16.self) }
        XCTAssertEqual(bitsPerSample, 16)

        // 4. Verify AVAudioPlayer can instantiate and parse the in-memory PCM WAV
        XCTAssertNoThrow(try {
            let player = try AVAudioPlayer(data: wavData)
            XCTAssertGreaterThan(player.duration, 0.4)
        }())
    }

    func testNotesDefinedForAllSixEras() {
        let eraIDs = [
            "org.taskintosh.era.windows95",
            "org.taskintosh.era.windowsxp",
            "org.taskintosh.era.windows7",
            "org.taskintosh.era.windows8",
            "org.taskintosh.era.windows10",
            "org.taskintosh.era.windows11",
            "org.taskintosh.era.customfallback"
        ]

        for id in eraIDs {
            let notes = EraSoundManager.notes(for: id)
            XCTAssertFalse(notes.isEmpty, "Era notes for \(id) should not be empty")

            for note in notes {
                XCTAssertGreaterThan(note.frequency, 20.0, "Frequency must be in audible range for \(id)")
                XCTAssertLessThan(note.frequency, 15000.0, "Frequency must be below 15kHz for \(id)")
                XCTAssertGreaterThan(note.duration, 0.0, "Note duration must be positive for \(id)")
                XCTAssertGreaterThan(note.volume, 0.0, "Note volume must be positive for \(id)")
                XCTAssertLessThanOrEqual(note.volume, 1.0, "Note volume must not exceed 1.0 for \(id)")
                XCTAssertFalse(note.harmonics.isEmpty, "Note harmonics must not be empty for \(id)")
            }

            // Synthesize and verify WAV plays
            let data = ProceduralSoundSynthesizer.synthesizeWAV(notes: notes)
            XCTAssertGreaterThan(data.count, 44)
            XCTAssertNoThrow(try AVAudioPlayer(data: data))
        }
    }

    @MainActor
    func testSoundEnabledToggleAndPersistence() {
        let manager = EraSoundManager.shared

        // Default should be enabled
        XCTAssertTrue(manager.isSoundEnabled)

        // Toggle to disabled
        manager.isSoundEnabled = false
        XCTAssertFalse(manager.isSoundEnabled)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: EraSoundManager.preferenceKey), false)

        // Toggle back to enabled
        manager.isSoundEnabled = true
        XCTAssertTrue(manager.isSoundEnabled)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: EraSoundManager.preferenceKey), true)
    }

    @MainActor
    func testSoundDataCaching() {
        let manager = EraSoundManager.shared
        let data1 = manager.soundData(for: "org.taskintosh.era.windows95")
        let data2 = manager.soundData(for: "org.taskintosh.era.windows95")
        XCTAssertEqual(data1, data2)
        XCTAssertGreaterThan(data1.count, 44)
    }

    @MainActor
    func testCustomStartupSoundDiscovery() throws {
        let manager = EraSoundManager.shared
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dummyAudioData = ProceduralSoundSynthesizer.synthesizeWAV(notes: [
            ProceduralAudioNote(frequency: 440, startTime: 0, duration: 0.1)
        ])

        // 1. Era without audio file -> nil
        let manifest = EraManifest(id: "custom.test", name: "Custom Test", version: "1.0", author: "Tester", eraPeriod: "2000", description: "Test")
        let packageWithoutAudio = EraPackage(rootURL: tempDir, manifest: manifest)
        XCTAssertNil(manager.findCustomStartupAudio(in: packageWithoutAudio))

        // 2. Era with assets/startup.wav -> detected
        let assetsDir = tempDir.appendingPathComponent("assets")
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        let soundURL = assetsDir.appendingPathComponent("startup.wav")
        try dummyAudioData.write(to: soundURL)

        let detected = manager.findCustomStartupAudio(in: packageWithoutAudio)
        XCTAssertNotNil(detected)
        XCTAssertEqual(detected?.lastPathComponent, "startup.wav")
    }
}
