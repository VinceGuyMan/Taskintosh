# Changelog

All notable changes to the **Taskintosh** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-02

### Added - Initial Phase 1 Release
- **Native macOS Architecture**:
  - `TaskbarPanel`: Borderless, non-activating `NSPanel` at `.statusBar` level with `.canJoinAllSpaces` and `.fullScreenAuxiliary`.
  - `RunningAppWatcher`: Real-time tracking of running macOS regular GUI applications using `NSWorkspace` notifications.
  - Multi-tier window management: Tier 1 (App-level mode with zero permissions required) and Tier 2 (Accessibility `AXUIElement` window-level inspection).
  - `DisplayManager`: Dynamic geometry management across multiple monitors and display resolution changes.
  - `SystemMonitor`: Real-time system clock, volume observer, and battery status monitor.
  - `AppCatalog`: Background application discovery across `/Applications` and `/System/Applications`.
- **Era Package Runtime (`.taskintosh-era`)**:
  - Modular package format supporting declarative `manifest.json`, `layout.json`, `theme.json`, and `behaviors.json`.
  - `EraManager`: Dynamic discovery across bundled resources and `~/Library/Application Support/Taskintosh/Eras/`.
  - Live Era switching without restarting the application.
  - In-app Era pack import capability.
- **Reference Era: Windows 95 Classic**:
  - Pixel-accurate 3D bevel renderer (`BevelRenderer`) supporting raised, sunken, etched, and 50% checkerboard dither patterns.
  - Classic Start button with original 4-quadrant retro emblem and tactile bevels.
  - Start Menu featuring vertical rotated *"Taskintosh 95"* gradient banner, Programs cascade, Documents, Settings, Find, Help, Run, and Shut Down.
  - Sunken system tray with live clock, volume icon, and Era Switcher icon.
  - Interactive **Run Dialog** and **Shut Down Dialog**.
  - Right-click taskbar context menu with Task Manager (Activity Monitor), Show Desktop, Auto-hide, and Era Properties.
  - Smooth auto-hide controller with mouse tracking edge trigger.
- **Clean-Room Legal Compliance**:
  - Original vector and procedural SVG/CoreGraphics icons.
  - No copyrighted Microsoft assets, logos, or sounds required.
- **Documentation & Tooling**:
  - `README.md`, `ARCHITECTURE.md`, `ERA-SPEC.md`, `DEVELOPMENT.md`, `ROADMAP.md`, `LEGAL-ASSET-NOTES.md`, `CHANGELOG.md`.
  - Build automation scripts (`build.sh`, `run.sh`, `package-app.sh`) and Finder double-clickable `Launch Taskintosh.command`.
  - Comprehensive unit test suite with 10 passing tests.
