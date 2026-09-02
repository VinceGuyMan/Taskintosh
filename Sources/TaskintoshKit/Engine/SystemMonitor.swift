import AppKit
import Combine
import IOKit.ps

public final class SystemMonitor: ObservableObject {
    public static let shared = SystemMonitor()

    @Published public private(set) var timeString: String = ""
    @Published public private(set) var dateString: String = ""
    @Published public private(set) var volumeLevel: Int = 50 // 0 - 100
    @Published public private(set) var hasBattery: Bool = false
    @Published public private(set) var batteryPercentage: Int = 100
    @Published public private(set) var isCharging: Bool = false

    private var timer: AnyCancellable?
    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()

    public init() {
        timeFormatter.dateFormat = "h:mm a"
        dateFormatter.dateStyle = .full

        updateClock()
        updateBattery()
        updateVolume()

        // Tick timer every second for clock updates
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateClock()
                self?.updateBattery()
            }
    }

    public func updateClock() {
        let now = Date()
        self.timeString = timeFormatter.string(from: now)
        self.dateString = dateFormatter.string(from: now)
    }

    public func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            self.hasBattery = false
            return
        }

        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let current = desc[kIOPSCurrentCapacityKey] as? Int,
                   let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 {
                    self.hasBattery = true
                    self.batteryPercentage = Int((Double(current) / Double(max)) * 100.0)
                    self.isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
                    return
                }
            }
        }
    }

    public func updateVolume() {
        // Read volume via AppleScript
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let script = "output volume of (get volume settings)"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                let descriptor = appleScript.executeAndReturnError(&error)
                if error == nil {
                    let vol = Int(descriptor.int32Value)
                    DispatchQueue.main.async {
                        self?.volumeLevel = vol
                    }
                }
            }
        }
    }

    public func setVolume(_ volume: Int) {
        let clamped = max(0, min(100, volume))
        self.volumeLevel = clamped
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "set volume output volume \(clamped)"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                _ = appleScript.executeAndReturnError(&error)
            }
        }
    }
}
