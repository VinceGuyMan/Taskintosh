import Foundation
import CoreGraphics

/// Supported historical Windows eras for procedural update simulation.
public enum WindowsEra: String, CaseIterable, Codable, Sendable, Identifiable {
    case win95 = "Windows 95"
    case win98 = "Windows 98"
    case winME = "Windows ME"
    case winXP = "Windows XP"
    case winVista = "Windows Vista"
    case win7 = "Windows 7"
    case win8 = "Windows 8"
    case win8_1 = "Windows 8.1"
    case win10 = "Windows 10"
    case win11 = "Windows 11"

    public var id: String { rawValue }

    /// Canonical short identifier for CLI and serialization
    public var shortIdentifier: String {
        switch self {
        case .win95: return "win95"
        case .win98: return "win98"
        case .winME: return "winme"
        case .winXP: return "winxp"
        case .winVista: return "winvista"
        case .win7: return "win7"
        case .win8: return "win8"
        case .win8_1: return "win81"
        case .win10: return "win10"
        case .win11: return "win11"
        }
    }

    /// Primary visual presentation family
    public enum PresentationFamily: String, Codable, Sendable {
        case classicDialog     // 95, 98, ME: Beveled 3D windows, chunky progress blocks, copy details
        case lunaWizard        // XP: Blue header banner, shield, wizard stages
        case aeroGlass         // Vista: Translucent/Aero glass dark frame, glowing teal progress
        case blueTheater       // 7: Iconic "Installing update X of Y", "Do not turn off your computer"
        case metroFullscreen   // 8, 8.1: Minimal full-bleed, giant percentage, restrained copy
        case ringSpinner       // 10: "Working on updates", dotted circular spinner, restart theater
        case modernMinimal     // 11: "Updates are underway", smooth fluid ring, mica dark atmosphere
    }

    public var presentationFamily: PresentationFamily {
        switch self {
        case .win95, .win98, .winME:
            return .classicDialog
        case .winXP:
            return .lunaWizard
        case .winVista:
            return .aeroGlass
        case .win7:
            return .blueTheater
        case .win8, .win8_1:
            return .metroFullscreen
        case .win10:
            return .ringSpinner
        case .win11:
            return .modernMinimal
        }
    }

    /// Exact window dimensions for clean popup presentation over the desktop.
    public var windowSize: CGSize {
        switch presentationFamily {
        case .classicDialog:
            // Authentic Win32 compact dialog dimensions (350x195)
            return CGSize(width: 350, height: 195)
        case .lunaWizard:
            // Windows XP Luna setup wizard (480x350)
            return CGSize(width: 480, height: 350)
        case .aeroGlass:
            // Windows Vista Aero dialog (490x320)
            return CGSize(width: 490, height: 320)
        case .blueTheater, .metroFullscreen, .ringSpinner, .modernMinimal:
            // Modern update theater (540x380)
            return CGSize(width: 540, height: 380)
        }
    }

    /// Typical default file extension flavors emphasized during updates in this era
    public var characteristicExtensions: [String] {
        switch self {
        case .win95, .win98, .winME:
            return [".DLL", ".VXD", ".SYS", ".INI", ".INF", ".DRV"]
        case .winXP:
            return [".dll", ".cab", ".sys", ".exe", ".cat", ".cpl"]
        case .winVista, .win7:
            return [".dll", ".mum", ".cat", ".manifest", ".msu", ".sys"]
        case .win8, .win8_1:
            return [".dll", ".appx", ".cab", ".dat", ".mum"]
        case .win10, .win11:
            return [".dll", ".cab", ".dat", ".json", ".msix", ".sys"]
        }
    }

    /// Era-specific default headline
    public var defaultHeadline: String {
        switch self {
        case .win95:
            return "Windows 95 Setup & Update"
        case .win98:
            return "Windows 98 Second Edition Update"
        case .winME:
            return "Windows Millennium Edition Update"
        case .winXP:
            return "Windows XP Automatic Updates"
        case .winVista:
            return "Windows Vista Service Pack Update"
        case .win7:
            return "Windows 7 Update"
        case .win8:
            return "Configuring Windows updates"
        case .win8_1:
            return "Setting up updates for Windows 8.1"
        case .win10:
            return "Working on updates"
        case .win11:
            return "Updates are underway"
        }
    }

    /// Era-specific default warning/subheadline
    public var defaultWarningMessage: String {
        switch self {
        case .win95, .win98, .winME:
            return "Windows is updating your system files and registry settings..."
        case .winXP:
            return "Please wait while Setup copies files to your computer."
        case .winVista:
            return "Configuring updates: Stage 3 of 3. Do not turn off your computer."
        case .win7:
            return "Do not turn off your computer."
        case .win8, .win8_1:
            return "Don't turn off your PC. This will take a while."
        case .win10:
            return "Don't turn off your PC. This will take a while. Your PC will restart several times."
        case .win11:
            return "Please keep your computer on and plugged in."
        }
    }

    /// Maps Taskintosh era manifest ID string (e.g. "windows-95", "WindowsXP", etc.) to WindowsEra.
    public static func from(taskintoshEraID: String) -> WindowsEra {
        let normalized = taskintoshEraID
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")

        if normalized.contains("win95") || normalized.contains("95") {
            return .win95
        } else if normalized.contains("win98") || normalized.contains("98") {
            return .win98
        } else if normalized.contains("winme") || normalized.contains("millennium") {
            return .winME
        } else if normalized.contains("winxp") || normalized.contains("xp") {
            return .winXP
        } else if normalized.contains("vista") {
            return .winVista
        } else if normalized.contains("win7") || normalized.contains("7") {
            return .win7
        } else if normalized.contains("81") || normalized.contains("win81") || normalized.contains("windows81") {
            return .win8_1
        } else if normalized.contains("8") || normalized.contains("win8") || normalized.contains("windows8") {
            return .win8
        } else if normalized.contains("11") || normalized.contains("win11") || normalized.contains("windows11") {
            return .win11
        } else if normalized.contains("10") || normalized.contains("win10") || normalized.contains("windows10") {
            return .win10
        }

        return .winXP // Sensible default for Taskintosh
    }
}
