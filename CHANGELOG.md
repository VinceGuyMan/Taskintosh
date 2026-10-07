# Changelog

All notable changes to **Taskintosh** are documented here. The project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-07

### Added

- Suite of 6 cinematic transitions for switching between taskbar generations:
  - **Smooth Crossfade**: Silky smooth opacity dissolve between generations with eased height expansion.
  - **Slide & Push**: Tactile generation push with dimensional seam illumination.
  - **Scanline Curtain Wipe**: Futuristic horizontal sweep with glowing neon beam.
  - **Retro CRT Morph**: Nostalgic cathode-ray tube phosphor beam collapse and expand.
  - **Aero Glass Bloom**: Translucent frosted glass bloom solidifying into focus.
  - **Time Warp Dither**: Digital matrix block dissolution with retro scanlines.
  - **Random Cycle Mode**: Automatically cycles through all 6 effects on each generation switch.
  - Dropdown selector added to the Era Manager & Properties window with persistent user preference.
  - Smooth animated height resizing coordinating with the macOS window layout coordinator.
- Clean-room procedural generation startup sounds:
  - Procedural sound synthesizer generating in-memory 44.1kHz 16-bit PCM RIFF WAVE audio with custom ADSR envelopes, additive harmonics, and zero bundled proprietary media files in strict compliance with `LEGAL-ASSET-NOTES.md`.
  - Signature musical chord voicings matching each operating system generation:
    - **Windows 95 Classic**: Floating ambient pentatonic chord swell (Db-Ab-Db-F-Ab-C-F).
    - **Windows XP**: Cheerful four-tone ascending bell chime (Eb-Bb-Ab-Eb).
    - **Windows 7**: Translucent Aero Glass acoustic marimba (C-G-E-C).
    - **Windows 8**: Minimalist digital two-tone pulse (F-C).
    - **Windows 10**: Atmospheric triad notification swell (D-A-F#).
    - **Windows 11**: Ethereal Fluent acoustic breath chord (B-F#-D#-G#).
  - Integrated startup sound playback triggered upon switching taskbar generations.
  - Added `[🔊 Sound]` / `[🔇 Muted]` toggle and `[▶ Preview Sound]` audition button in the Era Manager & Properties window.
  - Extensibility for third-party era packages with automatic discovery of custom audio assets (`startup.wav`, `startup.mp3`, `startup.aiff`, `startup.m4a`).
- In-place application updater integrated into the Settings & Era Manager window:
  - Added interactive top icon button with cursor feedback, tooltips, and real-time status.
  - Automatically checks GitHub releases for universal macOS application packages (`.zip`).
  - Downloads and extracts updates directly into the running app's location on disk, preserving file attributes and Gatekeeper quarantine flags before seamlessly relaunching.
  - Automatic fallback mechanism directing users to the project's GitHub releases page if releases lack attached package archives, encounter rate limits, or suffer network interruptions.
  - 16 new unit tests covering transitions, audio synthesis, RIFF headers, era voicings, semantic version comparison, GitHub release decoding, relaunch script generation, app spot resolution, and mock network flows.

### Fixed

- **Automatic Window Avoidance & Layout**:
  - Fixed work area coordinate calculation in `TaskbarWindowLayoutCoordinator` to respect `screen.visibleFrame` and prevent WindowServer from clamping tall windows back under the taskbar.
  - Resolved dynamic era re-adjustment when switching between taskbars of different heights (e.g. 28px vs 48px).
  - Added periodic common-mode run loop checking (1.5s) and workspace lifecycle observers to adjust windows launched after Taskintosh or moved near the bottom screen edge.
  - Added ad-hoc bundle codesigning (`org.taskintosh.Taskintosh`) and sealed resource binding in `package-app.sh` so macOS TCC reliably identifies and preserves Accessibility privileges.
  - Added "Accessibility & Window Layout..." shortcuts in the menu bar status item, taskbar context menu, and Era Manager window.

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
