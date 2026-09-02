# Taskintosh Roadmap

> *“The wrong taskbar for the right computer.”*

This roadmap outlines the planned evolution of Taskintosh across desktop computing history.

---

## Phase 1: Foundation & Windows 95 (Current Release)
- [x] Native macOS Engine (`TaskintoshKit`) with `NSWorkspace` app monitoring.
- [x] Multi-monitor geometry calculations via `DisplayManager`.
- [x] Decoupled Era Runtime & `.taskintosh-era` package loader.
- [x] Pixel-accurate 3D bevel rendering (`BevelRenderer`) with 50% dither patterns.
- [x] Original vector & procedural asset pipeline (100% clean-room).
- [x] Windows 95 Classic reference Era (`Windows95.taskintosh-era`).
- [x] Start Menu with Programs cascade, Run dialog, and Shut Down dialog.
- [x] System tray with sunken bevel and real-time clock.
- [x] Auto-hide mechanics with edge hover trigger.
- [x] Initial Era Manager with installed era browser and live switching.
- [x] Automated unit test suite and packaging scripts.

---

## Phase 2: The Late 90s (Windows 98, ME, 2000)
- [ ] **QuickLaunch Toolbar**: Pinned shortcuts alongside the Start button with drag-and-drop reordering.
- [ ] **Gradient Menus**: Multi-color menu header banners and customizable Start menu styling.
- [ ] **Volume & Status Tray Sliders**: Interactive popup sliders for macOS audio and screen brightness.
- [ ] **Desktop Toolbars**: Additional detachable toolbars (Address bar, Links bar).

---

## Phase 3: The 2000s & Luna (Windows XP)
- [ ] **Luna Visual Styles**:
  - Blue (default Luna)
  - Olive Green (Homestead)
  - Metallic Silver
  - Royale / Energy Blue (Media Center Edition)
  - Zune Theme
- [ ] **Two-Column Start Menu**: Pinned apps on the left, system locations (My Documents, Control Panel) on the right.
- [ ] **Task Grouping**: "Group similar taskbar buttons" when screen space becomes constrained.
- [ ] **Notification Balloons**: Balloon-style notification toasts integrating with macOS UserNotifications.

---

## Phase 4: The Aero Era (Windows Vista & Windows 7)
- [ ] **Aero Glass Rendering**: Native translucent glass with blurred desktop refraction using macOS CoreImage `CIGaussianBlur` / `CABackdropLayer`.
- [ ] **Live Window Thumbnails**: Hovering taskbar buttons reveals real-time window preview thumbnails captured via `CGWindowListCreateImage`.
- [ ] **Superbar Pinning**: Windows 7 style combined application launcher and running task indicators.
- [ ] **Jump Lists**: Right-click context menus with recent files and application actions.

---

## Phase 5: Modern Eras (Windows 8, 10, 11)
- [ ] **Windows 8 Charms / Start Screen Concept**: Full-screen tile launcher overlay option.
- [ ] **Windows 10 Fluent Style**: Dark/light mode theme switching with acrylic blur.
- [ ] **Windows 11 Centered Taskbar**: Centered taskbar icons with customizable alignment (Left vs. Center).

---

## Phase 6: Alternative Desktop History & Community Ecosystem
- [ ] **Alternative OS Eras**:
  - NeXTSTEP / OPENSTEP Shelf
  - BeOS Tracker Deskbar
  - Classic Macintosh System 7 / OS 8 Menu & Control Strip
  - AmigaOS Workbench
- [ ] **Community Era Marketplace**: In-app catalog to browse, preview, and download community-created `.taskintosh-era` packages directly from GitHub.
- [ ] **Theme Studio**: Visual Era creator allowing users to design and export `.taskintosh-era` packs without writing JSON manually.
