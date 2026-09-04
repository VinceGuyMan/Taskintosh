# Changelog

All notable changes to **Taskintosh** are documented here. The project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-04

### Fixed

- Restored mouse interaction for classic Windows Update buttons by excluding decorative bevel overlays from hit testing.
- Removed rounded native window chrome from clean classic dialogs so Win95/98/ME updates render as square period-authentic windows.
- Renamed classic dialog titles from “Setup” to “Update” to accurately describe the simulated experience.

### Verification

- 283 ProceduralWindowsUpdate runner checks passed.

## [1.0.0] - 2026-09-03

### Added

- Six clean-room reference eras: Windows 95, Windows XP, Windows 7, Windows 8, Windows 10, and Windows 11.
- Era-specific taskbars, Start menus, system trays, task buttons, Run and shutdown dialogs, and update presentations.
- The `ProceduralWindowsUpdate` module, including era-matched update windows, deterministic update sessions, close/cancel handling, and animated progress treatments.
- Optional Cake-layer interaction polish: animated update progress, tile and pinned-app hover feedback, drag reordering, and per-era pinned-layout persistence.
- Bundled era packages plus custom-era discovery and import support.

### Fixed

- Start-menu text and tile overflow across the supported eras.
- Windows XP All Programs behavior so its cascade remains available until it is toggled or dismissed elsewhere.
- Update window close actions across all supported eras.
- Persistence of intentionally empty pinned layouts; Reset restores the canonical layout.

### Verification

- 47 Taskintosh XCTest cases passed.
- 283 ProceduralWindowsUpdate runner checks passed.
- Production build completed successfully on macOS with Xcode Beta.
