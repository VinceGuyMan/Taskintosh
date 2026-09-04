# Taskintosh Roadmap

> *“Desktop history, openly rebuilt for Mac.”*

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

## Supported Era Scope

The current supported release focuses on six polished reference eras: Windows 95, XP, 7, 8, 10, and 11. Experimental Windows 98, ME, 2000, Vista, System 7, NeXTSTEP, BeOS, and AmigaOS packs are retained under `ArchivedEras/` for possible future refinement and are not packaged.

## Future Era Work

- [ ] Revisit archived historical eras only after the six supported eras meet release-quality visual and interaction standards.

---

## Windows XP Luna (Supported)
- [x] **Luna Visual Style**: Royal blue Luna taskbar with curved green Start pill.
- [x] **Two-Column Start Menu**: Pinned apps on the left, user profile header and system locations on the right.
- [x] **Era Package**: Windows XP Luna (`WindowsXP.taskintosh-era`).

---

## Windows 7 Superbar (Supported)
- [x] **Aero Glass Rendering**: Translucent dark glass styling with specular highlight lines.
- [x] **Superbar Styling**: Windows 7 40px Superbar with square icon-only button plates.
- [x] **Aero Peek**: Far-right screen desktop peek button.
- [x] **Era Package**: Windows 7 Superbar (`Windows7.taskintosh-era`).

---

## Modern Eras (Windows 8, 10, 11) (Supported)
- [x] **Windows 8 Flat Tiles**: Sharp flat monochrome emblem and accent underline indicators.
- [x] **Windows 10 Acrylic**: Dark acrylic taskbar styling.
- [x] **Windows 11 Centered Taskbar**: Centered taskbar icons with mica translucency and rounded pill plates.
- [x] **Era Packages**: Windows 8.1, Windows 10, and Windows 11.

---

## Future Alternative Desktop History
- [ ] **Alternative OS Eras**:
  - Classic Macintosh System 7 (`System7.taskintosh-era`): Top desktop menu bar with retro Apple menu and right-side app switcher.
  - NeXTSTEP / OPENSTEP (`NeXTSTEP.taskintosh-era`): Right-docked vertical shelf with 64px 3D beveled tiles.
  - BeOS Deskbar (`BeOS.taskintosh-era`): Modular top deskbar with blue/red Be logo button.
  - AmigaOS Workbench (`AmigaOS.taskintosh-era`): Royal blue and vibrant orange high-contrast title bar with depth gadget.
- [ ] **Community Era Marketplace**: In-app catalog to browse, preview, and download community-created `.taskintosh-era` packages directly from GitHub.
- [ ] **Theme Studio**: Visual Era creator allowing users to design and export `.taskintosh-era` packs without writing JSON manually.
