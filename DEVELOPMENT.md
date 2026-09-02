# Taskintosh Development Guide

This guide covers setting up the development environment, compiling, running tests, and debugging Taskintosh.

---

## Prerequisites

- **macOS**: 13.0 (Ventura) or later (Apple Silicon or Intel).
- **Toolchain**: Xcode 15+ or Swift 5.9+ toolchain (`swift --version`).
- **Permissions**: No special entitlements or Developer ID certificates are required for standard local development builds.

---

## Building the Project

Taskintosh is configured as a standard Swift Package Manager project with modular targets:
- `TaskintoshKit`: Core engine and era runtime library.
- `Taskintosh`: Native macOS application executable.
- `TaskintoshTests`: Unit test suite.

### Debug Build
```bash
swift build
```

### Release Build
```bash
./scripts/build.sh
```

### Assemble the Native Application Bundle (`Taskintosh.app`)
```bash
./scripts/package-app.sh
```
This script compiles the release binary, creates `build/Taskintosh.app`, writes the `Info.plist` (configuring `LSUIElement` so Taskintosh runs as an accessory without cluttering the macOS Dock), and bundles the default Era packs.

---

## Running Taskintosh

### Method 1: Double-Click Finder Launcher
Double-click `Launch Taskintosh.command` in the project root. This automatically runs the package script and opens the native app bundle.

### Method 2: Command Line Run
```bash
./scripts/run.sh
```
or
```bash
open build/Taskintosh.app
```

---

## Running Automated Tests

Run the test suite using `swift test`:
```bash
swift test
```

The test suite validates:
- `EraPackageTests`: Loading, JSON decoding, manifest parsing, hex color conversion, and procedural icon generation.
- `BevelRendererTests`: 3D color derivation and bounds safety checks.
- `TaskItemTests`: Process ID tracking, equality, and hash consistency.
- `AutoHideStateMachineTests`: Edge enum coverage and display geometry calculations.

---

## Debugging & Local Testing Tips

### macOS Dock Auto-Hide
If the macOS native Dock is docked at the bottom of the screen, it may overlap with Taskintosh. You can toggle auto-hide for the native Dock using:
```bash
defaults write com.apple.dock autohide -bool true && killall Dock
```
To restore the Dock:
```bash
defaults write com.apple.dock autohide -bool false && killall Dock
```
These actions can also be executed directly via the buttons in the Taskintosh Era Manager.

### Testing Running Applications
Launch apps like Safari, Terminal, and Calculator. Notice:
1. Dynamic task buttons appear in the taskbar.
2. Clicking a button brings that app to the foreground.
3. Clicking the active button hides/minimizes that app.
4. Quitting an app immediately removes its button from the taskbar.

### Testing the Start Menu & Dialogs
- Click the Start button to test menu cascades.
- Test **Run...**: type `https://github.com` or `Calculator` or a shell command.
- Test **Shut Down...**: opens confirmation prompt without executing destructive actions unintentionally.
