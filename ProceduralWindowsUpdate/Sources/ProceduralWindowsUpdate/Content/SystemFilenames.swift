import Foundation

/// Authentic system filenames, folders, and components tailored to historical Windows eras.
public struct SystemFilenames {

    public static func paths(for era: WindowsEra) -> [String] {
        switch era {
        case .win95, .win98, .winME:
            return [
                #"C:\WINDOWS\SYSTEM\"#,
                #"C:\WINDOWS\"#,
                #"C:\WINDOWS\INF\"#,
                #"C:\WINDOWS\COMMAND\"#,
                #"C:\WINDOWS\SYSTEM\VMM32\"#
            ]
        case .winXP:
            return [
                #"C:\WINDOWS\System32\"#,
                #"C:\WINDOWS\SoftwareDistribution\Download\"#,
                #"C:\WINDOWS\System32\drivers\"#,
                #"C:\WINDOWS\inf\"#,
                #"C:\WINDOWS\Resources\Themes\"#
            ]
        case .winVista, .win7:
            return [
                #"C:\Windows\System32\"#,
                #"C:\Windows\SysWOW64\"#,
                #"C:\Windows\WinSxS\"#,
                #"C:\Windows\SoftwareDistribution\Download\"#,
                #"C:\Windows\servicing\Packages\"#
            ]
        case .win8, .win8_1:
            return [
                #"C:\Windows\System32\"#,
                #"C:\Windows\WinSxS\"#,
                #"C:\Program Files\WindowsApps\"#,
                #"C:\Windows\SoftwareDistribution\Download\"#,
                #"C:\Windows\System32\DriverStore\"#
            ]
        case .win10, .win11:
            return [
                #"C:\Windows\System32\"#,
                #"C:\Windows\WinSxS\"#,
                #"C:\Windows\SoftwareDistribution\Download\"#,
                #"C:\Windows\SystemApps\"#,
                #"C:\ProgramData\Microsoft\Windows\Update\"#
            ]
        }
    }

    public static func files(for era: WindowsEra) -> [String] {
        switch era {
        case .win95, .win98, .winME:
            return [
                "KERNEL32.DLL", "USER32.DLL", "GDI32.DLL", "SHELL32.DLL",
                "VMM32.VXD", "SYSTEM.INI", "WIN.INI", "COMMDLG.DLL",
                "EXPLORER.EXE", "MSVCRT.DLL", "SETUPX.DLL", "MSNET32.DLL",
                "TAPI32.DLL", "WINSOCK.DLL", "CAB32.DLL", "VCOMM.VXD",
                "VTD.VXD", "SMARTDRV.EXE", "CONFIG.SYS", "AUTOEXEC.BAT",
                "MSHTML.DLL", "SHDOCVW.DLL", "URLMON.DLL", "WININET.DLL"
            ]
        case .winXP:
            return [
                "ntoskrnl.exe", "hal.dll", "winsrv.dll", "shell32.dll",
                "ole32.dll", "wuauclt.exe", "advapi32.dll", "crypt32.dll",
                "shlwapi.dll", "sp2.cab", "themeui.dll", "uxtheme.dll",
                "luna.msstyles", "tcpip.sys", "winlogon.exe", "csrss.exe",
                "rundll32.exe", "msxml3.dll", "wuauserv.dll", "sp3_qfe.cat"
            ]
        case .winVista, .win7:
            return [
                "dwm.exe", "aero.msstyles", "uxtheme.dll", "wer.dll",
                "wuaueng.dll", "trustedinstaller.exe", "tiworker.exe",
                "ntdll.dll", "dxgi.dll", "d3d11.dll", "winsxs.dll",
                "CBS.log", "SxS.dll", "wsmprovhost.exe", "update.mum",
                "package_for_rollup.cat", "bcrypt.dll", "shell32.dll"
            ]
        case .win8, .win8_1:
            return [
                "twinui.dll", "modern.appx", "appxdeploymentextensions.dll",
                "windows.ui.xaml.dll", "immersivehost.exe", "tiworker.exe",
                "dism.exe", "dismcore.dll", "update.mum", "twinapi.dll",
                "wuauserv.dll", "usoclient.exe", "ntoskrnl.exe"
            ]
        case .win10, .win11:
            return [
                "windows.ui.shell.dll", "startmenuexperiencehost.exe",
                "searchui.exe", "shellexperiencehost.exe", "fluent_mica.dll",
                "usoclient.exe", "wuaueng.dll", "tiworker.exe", "wuauserv.dll",
                "package_manager.json", "appxmanifest.xml", "CoreMessaging.dll",
                "DirectComposition.dll", "windows.staterepository.dll"
            ]
        }
    }

    public static func believableMessages(for era: WindowsEra, stage: StageKind) -> [String] {
        if era == .win95 || era == .win98 || era == .winME {
            switch stage {
            case .checking:
                return [
                    "Preparing to install...",
                    "Please wait while Setup updates your system.",
                    "Checking installed system components..."
                ]
            case .downloading:
                return [
                    "Copying file...",
                    "Extracting files from cabinet archive...",
                    "Preparing setup files..."
                ]
            case .verifying:
                return [
                    "Verifying system file integrity...",
                    "Checking file versions...",
                    "Inspecting destination directories..."
                ]
            case .installing:
                return [
                    "Windows is updating the following files:",
                    "Copying file...",
                    "Updating system files and drivers..."
                ]
            case .configuring:
                return [
                    "Windows is updating your system settings...",
                    "Updating registry and system initialization files...",
                    "Configuring system components..."
                ]
            case .cleaningUp:
                return [
                    "Removing temporary setup files...",
                    "Cleaning temporary installation directories..."
                ]
            case .restarting:
                return [
                    "Windows is preparing to restart system services...",
                    "Restarting system settings..."
                ]
            case .finalizing:
                return [
                    "Windows has finished updating your system files.",
                    "Setup has completed updating your system."
                ]
            }
        }

        switch stage {
        case .checking:
            return [
                "Connecting to update catalog servers...",
                "Scanning component store for supersedence...",
                "Evaluating installed package prerequisites...",
                "Checking driver database for updated device INF files..."
            ]
        case .downloading:
            return [
                "Downloading cumulative update package delta payload...",
                "Receiving security definitions and metadata manifests...",
                "Streaming signed archive chunks from content delivery network...",
                "Caching CAB packages to local distribution folder..."
            ]
        case .verifying:
            return [
                "Verifying digital signatures (SHA-256 certificate chain)...",
                "Inspecting cryptographic checksum of unpacked manifests...",
                "Validating component store schema compatibility...",
                "Checking hash parity for staged binary catalogs..."
            ]
        case .installing:
            return [
                "Updating system components and dynamic link libraries...",
                "Installing security rollup and critical servicing stack...",
                "Replacing core binaries and updating system catalog...",
                "Committing staged updates to side-by-side assembly store...",
                "Registering updated COM interfaces and system controls..."
            ]
        case .configuring:
            return [
                "Configuring desktop services and subsystem settings...",
                "Rebuilding performance counter manifests...",
                "Applying system policy updates to registry hives...",
                "Optimizing background servicing schedules..."
            ]
        case .cleaningUp:
            return [
                "Cleaning temporary update staging directories...",
                "Purging superseded package payloads from download cache...",
                "Pruning obsolete driver INF records...",
                "Compressing transaction logs in software distribution store..."
            ]
        case .restarting:
            return [
                "Flushing disk caches and preparing subsystem handoff...",
                "Updating boot configuration data...",
                "Restarting virtual display and session manager..."
            ]
        case .finalizing:
            return [
                "Finalizing update operations...",
                "Verifying system state integrity...",
                "All updates successfully committed."
            ]
        }
    }
}
