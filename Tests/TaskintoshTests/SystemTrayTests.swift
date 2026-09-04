import XCTest
@testable import TaskintoshKit

final class SystemTrayTests: XCTestCase {
    func testSystemMonitorVolumeClampingAndMute() {
        let monitor = SystemMonitor.shared
        monitor.setVolume(150)
        XCTAssertEqual(monitor.volumeLevel, 100)

        monitor.setVolume(-20)
        XCTAssertEqual(monitor.volumeLevel, 0)

        monitor.setVolume(75)
        XCTAssertEqual(monitor.volumeLevel, 75)

        let initialMute = monitor.isMuted
        monitor.toggleMute()
        XCTAssertEqual(monitor.isMuted, !initialMute)
        monitor.setMuted(initialMute)
        XCTAssertEqual(monitor.isMuted, initialMute)
    }

    func testSystemMonitorDateTimeStrings() {
        let monitor = SystemMonitor.shared
        monitor.updateClock()
        XCTAssertFalse(monitor.timeString.isEmpty)
        XCTAssertFalse(monitor.dateShortString.isEmpty)
        XCTAssertFalse(monitor.dateLongString.isEmpty)
        XCTAssertFalse(monitor.dayNumberString.isEmpty)
        XCTAssertFalse(monitor.monthYearString.isEmpty)
    }

    func testTrayIconsGeneration() {
        let icons = ProceduralIcons.shared

        let soundNormal = icons.soundIcon(size: 16, color: .black, isMuted: false)
        XCTAssertEqual(soundNormal.size, NSSize(width: 16, height: 16))

        let soundMuted = icons.soundIcon(size: 16, color: .black, isMuted: true)
        XCTAssertEqual(soundMuted.size, NSSize(width: 16, height: 16))

        let netXP = icons.networkIcon(size: 16, isConnected: true, isWinXP: true)
        XCTAssertEqual(netXP.size, NSSize(width: 16, height: 16))

        let netWiFi = icons.networkIcon(size: 16, isConnected: true, isWiFi: true, isWinXP: false)
        XCTAssertEqual(netWiFi.size, NSSize(width: 16, height: 16))

        let batt = icons.batteryIcon(size: 16, percentage: 85, isCharging: true)
        XCTAssertEqual(batt.size, NSSize(width: 16, height: 16))

        let flag = icons.actionCenterFlagIcon(size: 14)
        XCTAssertEqual(flag.size, NSSize(width: 14, height: 14))

        let chevUp = icons.trayChevronIcon(size: 12, isUp: true)
        XCTAssertEqual(chevUp.size, NSSize(width: 12, height: 12))

        let chevDown = icons.trayChevronIcon(size: 12, isUp: false)
        XCTAssertEqual(chevDown.size, NSSize(width: 12, height: 12))
    }
}
