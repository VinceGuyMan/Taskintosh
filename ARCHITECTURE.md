# Taskintosh Architecture & Technical Design

This document details the architectural principles, component structure, and macOS system integrations of **Taskintosh**.

---

## High-Level Architecture

Taskintosh is structured into three clear layers:

```
+-------------------------------------------------------------------------+
|                              Taskintosh UI                              |
|   TaskbarPanel  |  TaskbarView  |  StartMenuWindow  |  AutoHideController|
|   RunDialog     |  ShutDownDialog | EraManagerWindow | TaskbarContextMenu|
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                               Era Runtime                               |
|   EraPackage (Loader) | EraManager (Catalog & Switching)                |
|   BevelRenderer (3D Graphics) | ProceduralIcons (Pixel Fallbacks)       |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                            Taskintosh Engine                            |
|   RunningAppWatcher (NSWorkspace) | DisplayManager (NSScreen Geometry)  |
|   AppCatalog (App Discovery)     | SystemMonitor (Clock, Battery, Vol) |
|   WindowAccessibilityBridge (Optional AXUIElement Window Inspection)    |
+-------------------------------------------------------------------------+
```

---

## 1. Native macOS Window & Panel Architecture

A reliable desktop taskbar requires precise window layering and behavior to coexist with macOS Spaces, Mission Control, and fullscreen apps.

### `TaskbarPanel` Configuration
- **Base Class**: `NSPanel` (with `.borderless` and `.nonactivatingPanel` style masks).
- **Window Level**: `.statusBar` (`CGWindowLevelForKey(.statusWindow)`). This places the panel above standard application windows without obscuring system alert modals or critical system overlays.
- **Collection Behavior**:
  - `.canJoinAllSpaces`: Ensures the taskbar stays visible when the user swipes between macOS Spaces / virtual desktops.
  - `.fullScreenAuxiliary`: Prevents the taskbar from being abruptly destroyed or frozen when interacting with macOS fullscreen spaces.
  - `.stationary`: Excludes the taskbar from being rearranged during Mission Control / Exposé gestures.
  - `.ignoresCycle`: Prevents Command-` window cycling from accidentally focusing the taskbar panel.
- **Activation Policy**: `NSApp.setActivationPolicy(.accessory)`. Running as an accessory agent ensures Taskintosh does not clutter the native macOS Dock with its own icon, fulfilling its role as a dedicated desktop environment utility.

---

## 2. Process & Window Management Strategy

Taskintosh uses a defensive, multi-tier strategy to monitor running applications and windows.

### Tier 1: App-Level Mode (Default, Zero Permissions Required)
- Uses `NSWorkspace.shared.runningApplications` filtered by `activationPolicy == .regular`.
- Subscribes to `NSWorkspace` notifications:
  - `didLaunchApplicationNotification`
  - `didTerminateApplicationNotification`
  - `didActivateApplicationNotification`
  - `didDeactivateApplicationNotification`
  - `didHideApplicationNotification`
  - `didUnhideApplicationNotification`
- **Activation**: `app.activate(options: [.activateIgnoringOtherApps])`.
- **Minimization / Hide**: If an already frontmost application's taskbar button is clicked, Taskintosh calls `app.hide()`. Clicking again calls `app.unhide()` and brings it to the foreground. This faithfully replicates the single-button minimize/restore interaction pattern.

### Tier 2: Window-Level Mode (Enhanced, Accessibility Permission)
- Handled by `WindowAccessibilityBridge`.
- When the user grants macOS Accessibility permissions, Taskintosh queries `AXUIElement` for the application's windows (`kAXWindowsAttribute`), window titles (`kAXTitleAttribute`), and minimization state (`kAXMinimizedAttribute`).
- Can trigger `kAXRaiseAction` on specific windows.
- If Accessibility permission is not granted, Taskintosh **automatically falls back** to Tier 1 without displaying blocking alerts or degraded performance.

---

## 3. Pixel-Accurate 3D Bevel Engine

A critical historical fidelity requirement is the rendering of 1990s 3D bevels. These are **not** drop shadows or CSS border approximations; they follow exact two-tone lighting models:

### Bevel Specifications
- **Light Source**: Upper-left (classic 45° desktop lighting).
- **Raised Bevel (Buttons, Start Button, Dialogs)**:
  - Top & Left Outer Line (1px): `lightHighlightColor` (`#FFFFFF`)
  - Bottom & Right Outer Line (1px): `darkShadowColor` (`#000000`)
  - Bottom & Right Inner Line (1px): `shadowColor` (`#808080`)
- **Sunken Bevel (Active/Pressed Buttons, System Tray, Input Fields)**:
  - Top & Left Outer Line (1px): `darkShadowColor` (`#000000`)
  - Top & Left Inner Line (1px): `shadowColor` (`#808080`)
  - Bottom & Right Outer Line (1px): `lightHighlightColor` (`#FFFFFF`)
- **50% Alternating Checkerboard Dither**:
  - The active taskbar button in Windows 95 uses an alternating pixel grid of `#C0C0C0` and `#FFFFFF` to provide tactile depth. `BevelRenderer.drawActiveDither` renders this directly into the CoreGraphics context with subpixel precision.

---

## 4. Auto-Hide State Machine

The auto-hide subsystem (`AutoHideController`) is decoupled from the UI rendering layer:

```
       +--------------+
       |   VISIBLE    |<-------------+
       +--------------+              |
              |                      |
    Mouse leaves taskbar             |
              |                      |
              v                      |
       +--------------+     Mouse hits bottom edge
       | DELAY TIMER  |     (3px trigger zone)
       +--------------+              |
              |                      |
      Delay expires (0.5s)           |
              |                      |
              v                      |
       +--------------+              |
       |    HIDDEN    |--------------+
       | (2px peek)   |
       +--------------+
```

- **Cancellation Rule**: If the Start Menu or a context menu is open, the auto-hide timer is canceled and the taskbar remains locked in the visible state until the menu closes.

---

## 5. Era Package Architecture & Discovery

Era definitions are decoupled from the compiled code. An Era package is represented by `EraPackage` and contains:
1. `manifest.json`: Package ID, human-readable name, era period, version, author, and description.
2. `layout.json`: Edge positioning, height, button min/max widths, item spacing.
3. `theme.json`: Hex color palette, typography settings, bevel styles, dither flags.
4. `behaviors.json`: Auto-hide timing, click action rules, grouping policies.
5. `assets/`: Optional custom vector (SVG) or bitmap icons.

### Resolution Hierarchy
When loading assets, `EraPackage` resolves in the following order:
1. In-memory asset cache.
2. Package `assets/` directory (SVG/PNG/ICO).
3. Built-in procedural vector renderer (`ProceduralIcons`).

### Search Paths
`EraManager` discovers installed Eras across three locations:
1. `~/Library/Application Support/Taskintosh/Eras/` (User-installed community packs).
2. Application Bundle `Resources/Eras/` (Built-in shipping eras).
3. Development workspace fallback (`Sources/TaskintoshKit/Resources/Eras/`).

When the user switches Eras, `EraManager.$activeEra` emits a reactive notification via Combine, prompting `TaskbarPanel` and `TaskbarView` to re-measure and redraw immediately without restarting the app.
