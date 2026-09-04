import AppKit
import Combine
import CoreWLAN
import IOKit.ps
import Network

public struct WiFiNetworkItem: Identifiable, Equatable {
    public let id: String
    public let ssid: String
    public let isConnected: Bool
    public let signalBars: Int // 1 to 4
    public let isSecured: Bool
    public let securityType: String
    public let signalNoiseDescription: String?

    public init(
        id: String = UUID().uuidString,
        ssid: String,
        isConnected: Bool,
        signalBars: Int,
        isSecured: Bool,
        securityType: String = "WPA2/WPA3",
        signalNoiseDescription: String? = nil
    ) {
        self.id = id
        self.ssid = ssid
        self.isConnected = isConnected
        self.signalBars = signalBars
        self.isSecured = isSecured
        self.securityType = securityType
        self.signalNoiseDescription = signalNoiseDescription
    }
}

public final class SystemMonitor: ObservableObject {
    public static let shared = SystemMonitor()

    @Published public private(set) var timeString: String = ""
    @Published public private(set) var dateString: String = ""
    @Published public private(set) var dateShortString: String = ""
    @Published public private(set) var dateLongString: String = ""
    @Published public private(set) var dayNumberString: String = ""
    @Published public private(set) var monthYearString: String = ""

    @Published public private(set) var volumeLevel: Int = 50 // 0 - 100
    @Published public private(set) var isMuted: Bool = false

    @Published public private(set) var hasBattery: Bool = false
    @Published public private(set) var batteryPercentage: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isConnectedToAC: Bool = false
    @Published public private(set) var isBatteryFullyCharged: Bool = false
    @Published public private(set) var powerSourceString: String = "Battery"
    @Published public private(set) var batteryTimeRemainingString: String? = nil

    @Published public private(set) var isNetworkConnected: Bool = true
    @Published public private(set) var isWiFi: Bool = false
    @Published public private(set) var networkDescription: String = "Connected"
    @Published public private(set) var connectedSSID: String? = nil
    @Published public private(set) var availableWiFiNetworks: [WiFiNetworkItem] = []
    @Published public private(set) var isScanningWiFi: Bool = false
    @Published public private(set) var lastScanDate: Date? = nil

    private var timer: AnyCancellable?
    private let timeFormatter = DateFormatter()
    private let dateShortFormatter = DateFormatter()
    private let dateLongFormatter = DateFormatter()
    private let dayFormatter = DateFormatter()
    private let monthYearFormatter = DateFormatter()

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "org.taskintosh.networkmonitor")
    private let scanQueue = DispatchQueue(label: "org.taskintosh.wifiscan", qos: .utility)

    public init() {
        timeFormatter.dateFormat = "h:mm a"
        dateShortFormatter.dateFormat = "M/d/yyyy"
        dateLongFormatter.dateStyle = .full
        dayFormatter.dateFormat = "d"
        monthYearFormatter.dateFormat = "MMMM yyyy"

        updateClock()
        updateBattery()
        updateVolume()
        startNetworkMonitoring()
        refreshWiFiNetworks()

        // Tick timer every second for clock & battery updates
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateClock()
                self?.updateBattery()
            }
    }

    deinit {
        pathMonitor.cancel()
    }

    public func updateClock() {
        let now = Date()
        self.timeString = timeFormatter.string(from: now)
        self.dateShortString = dateShortFormatter.string(from: now)
        self.dateLongString = dateLongFormatter.string(from: now)
        self.dateString = self.dateLongString
        self.dayNumberString = dayFormatter.string(from: now)
        self.monthYearString = monthYearFormatter.string(from: now)
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
                    self.isBatteryFullyCharged = (desc[kIOPSIsChargedKey] as? Bool) ?? (self.batteryPercentage >= 100)

                    let powerState = desc[kIOPSPowerSourceStateKey] as? String
                    self.isConnectedToAC = (powerState == kIOPSACPowerValue) || self.isCharging
                    self.powerSourceString = self.isConnectedToAC ? "Power Adapter" : "Battery"

                    if let timeToEmpty = desc[kIOPSTimeToEmptyKey] as? Int, timeToEmpty > 0 {
                        let hours = timeToEmpty / 60
                        let mins = timeToEmpty % 60
                        self.batteryTimeRemainingString = "\(hours) hr \(mins) min remaining"
                    } else if let timeToFull = desc[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                        let hours = timeToFull / 60
                        let mins = timeToFull % 60
                        self.batteryTimeRemainingString = "\(hours) hr \(mins) min until fully charged"
                    } else {
                        self.batteryTimeRemainingString = nil
                    }
                    return
                }
            }
        }
    }

    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = (path.status == .satisfied)
            let wifi = path.usesInterfaceType(.wifi)
            let desc: String
            if !connected {
                desc = "Not Connected"
            } else if wifi {
                desc = "Wi-Fi Connected"
            } else if path.usesInterfaceType(.wiredEthernet) {
                desc = "Wired Connection"
            } else {
                desc = "Internet Access"
            }

            DispatchQueue.main.async {
                self?.isNetworkConnected = connected
                self?.isWiFi = wifi
                self?.networkDescription = desc
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    public func refreshWiFiNetworks(force: Bool = false) {
        if !force, let last = lastScanDate, Date().timeIntervalSince(last) < 8.0 {
            return
        }

        self.isScanningWiFi = true

        // Fast CoreWLAN query for current active interface
        if let iface = CWWiFiClient.shared().interface() {
            if let activeSSID = iface.ssid(), !activeSSID.isEmpty {
                self.connectedSSID = activeSSID
            }
        }

        scanQueue.async { [weak self] in
            let scannedNetworks = self?.performSystemProfilerScan() ?? []
            DispatchQueue.main.async {
                self?.isScanningWiFi = false
                self?.lastScanDate = Date()
                if !scannedNetworks.isEmpty {
                    self?.availableWiFiNetworks = scannedNetworks
                    if let conn = scannedNetworks.first(where: { $0.isConnected }) {
                        self?.connectedSSID = conn.ssid
                    }
                }
            }
        }
    }

    private func performSystemProfilerScan() -> [WiFiNetworkItem] {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPAirPortDataType"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            if let output = String(data: data, encoding: .utf8) {
                return parseAirPortOutput(output)
            }
        } catch {
            // Fallback to CoreWLAN current interface if system_profiler fails
        }

        // Fallback using CoreWLAN single interface
        if let iface = CWWiFiClient.shared().interface(), let ssid = iface.ssid(), !ssid.isEmpty {
            let rssi = iface.rssiValue()
            let bars = barsForRssi(rssi)
            return [
                WiFiNetworkItem(
                    ssid: ssid,
                    isConnected: true,
                    signalBars: bars,
                    isSecured: true,
                    securityType: "WPA2/WPA3",
                    signalNoiseDescription: "\(rssi) dBm"
                )
            ]
        }
        return []
    }

    private func parseAirPortOutput(_ text: String) -> [WiFiNetworkItem] {
        var results: [WiFiNetworkItem] = []
        var seenSSIDs = Set<String>()

        let lines = text.components(separatedBy: .newlines)
        var currentSection: String = ""
        var currentSSID: String = ""
        var currentProps: [String: String] = [:]

        func commitCurrentNetwork() {
            guard !currentSSID.isEmpty, !seenSSIDs.contains(currentSSID) else { return }
            seenSSIDs.insert(currentSSID)

            let isConn = (currentSection == "Current")
            let secMode = currentProps["Security"] ?? "WPA2/WPA3"
            let isSecured = !secMode.lowercased().contains("none")
            let sigNoise = currentProps["Signal / Noise"]

            var bars = 3
            if let sigStr = sigNoise?.components(separatedBy: "/").first?.trimmingCharacters(in: .whitespaces) {
                let clean = sigStr.replacingOccurrences(of: "dBm", with: "").trimmingCharacters(in: .whitespaces)
                if let dBm = Int(clean) {
                    bars = barsForRssi(dBm)
                }
            }

            let item = WiFiNetworkItem(
                ssid: currentSSID,
                isConnected: isConn,
                signalBars: bars,
                isSecured: isSecured,
                securityType: secMode,
                signalNoiseDescription: sigNoise
            )
            results.append(item)
            currentSSID = ""
            currentProps.removeAll()
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Current Network Information:") {
                commitCurrentNetwork()
                currentSection = "Current"
                continue
            } else if trimmed.hasPrefix("Other Local Wi-Fi Networks:") {
                commitCurrentNetwork()
                currentSection = "Other"
                continue
            }

            guard !currentSection.isEmpty else { continue }

            if trimmed.hasSuffix(":") && !trimmed.contains(" ") && !trimmed.contains("/") {
                // Network name
                commitCurrentNetwork()
                currentSSID = String(trimmed.dropLast())
            } else if trimmed.hasSuffix(":") && (line.hasPrefix("            ") || line.hasPrefix("          ")) && !trimmed.contains("PHY Mode") && !trimmed.contains("Security") && !trimmed.contains("Channel") && !trimmed.contains("Network Type") && !trimmed.contains("Signal") {
                commitCurrentNetwork()
                currentSSID = String(trimmed.dropLast())
            } else if let colonIdx = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let val = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                currentProps[key] = val
            }
        }
        commitCurrentNetwork()

        // Sort: connected network first, then alphabetical by SSID
        results.sort { (a, b) -> Bool in
            if a.isConnected != b.isConnected {
                return a.isConnected && !b.isConnected
            }
            return a.ssid.localizedCaseInsensitiveCompare(b.ssid) == .orderedAscending
        }

        return results
    }

    private func barsForRssi(_ rssi: Int) -> Int {
        if rssi >= -55 { return 4 }
        if rssi >= -68 { return 3 }
        if rssi >= -80 { return 2 }
        return 1
    }

    public func updateVolume() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let script = """
            set v to output volume of (get volume settings)
            set m to output muted of (get volume settings)
            return (v as string) & "," & (m as string)
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                let descriptor = appleScript.executeAndReturnError(&error)
                if error == nil, let stringValue = descriptor.stringValue {
                    let parts = stringValue.components(separatedBy: ",")
                    let vol = parts.count > 0 ? (Int(parts[0]) ?? 50) : 50
                    let muted = parts.count > 1 ? (parts[1].lowercased() == "true") : false
                    DispatchQueue.main.async {
                        self?.volumeLevel = vol
                        self?.isMuted = muted
                    }
                }
            }
        }
    }

    public func setVolume(_ volume: Int) {
        let clamped = max(0, min(100, volume))
        self.volumeLevel = clamped
        if isMuted && clamped > 0 {
            self.isMuted = false
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "set volume output volume \(clamped)"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                _ = appleScript.executeAndReturnError(&error)
            }
        }
    }

    public func setMuted(_ muted: Bool) {
        self.isMuted = muted
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "set volume output muted \(muted ? "true" : "false")"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                _ = appleScript.executeAndReturnError(&error)
            }
        }
    }

    public func toggleMute() {
        setMuted(!isMuted)
    }
}
