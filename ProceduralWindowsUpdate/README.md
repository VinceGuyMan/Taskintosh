# ProceduralWindowsUpdate for Taskintosh

A self-contained, deterministic, procedural fake "Windows Update" engine and era-authentic presentation system built for Taskintosh on macOS.

---

## Executive Summary

Taskintosh brings nostalgic desktop eras to the Mac. **ProceduralWindowsUpdate** delivers a completely fake, theatrical Windows Update experience that accurately reproduces the visual styling, pacing, and behavior of each supported Windows era—without touching, downloading, installing, deleting, restarting, or altering anything on the user's Mac.

It is **100% theatrical procedural theater**:
- **Zero Real System Changes**: All file operations, KB identifiers, sizes, stages, logs, and simulated reboots are purely in-memory data structures.
- **Deterministic & Seedable**: Every session is uniquely generated via an internal PRNG from a `UInt64` seed. Replaying the same seed yields the exact same updates, progress curves, stalls, jumps, and text.
- **Authentic Period Fidelity**: The Windows 95/98/ME dialog is built to exact classic Win32 standards: compact 350×195 px geometry, solid `#C0C0C0` face, solid `#000080` navy title bar, 16×14 px close button with pixel-accurate `✕`, 2-tier dual-tone bevels, 16 px recessed chunky navy progress bar, authentic setup copy, and a single "Cancel" (or "OK") button.
- **Separation of Authenticity & Comedy**: Default mode is strictly 100% authentic Windows-era copy. Jokes, Taskintosh cultural exchange, and easter eggs appear only when explicitly requesting theatrical / high-vibes mode.
- **No Intrusive Modern Overlays**: Modern translucent emoji completion overlays have been completely removed from classic eras; classic dialogs transition seamlessly into their native "OK" state.
- **Clean Screenshot Preview**: Built-in screenshot mode renders only the classic dialog floating over an authentic `#008080` Windows teal desktop, with zero developer toolbars or floating buttons.
- **Never Traps the User**: Emergency exit mechanisms are baked in via the Escape key, Cancel buttons, and an explicit controller `cancel()` API.
- **Completely Isolated**: Built as an independent module with zero dependencies on in-progress Start menu or taskbar code, ready for one-line integration whenever Antigravity is ready.

---

## Architectural Overview

```
ProceduralWindowsUpdate/
├── Package.swift                                # Independent Swift Package (macOS 13+)
├── README.md                                    # This document
├── scripts/
│   ├── run-tests.sh                             # Automated test suite runner (71 tests)
│   └── run-preview.sh                           # Launches standalone interactive preview GUI
├── Sources/
│   └── ProceduralWindowsUpdate/
│       ├── ProceduralWindowsUpdate.swift        # Module facade & version info
│       ├── Eras/
│       │   └── WindowsEra.swift                 # Supported eras (95, 98, ME, XP, Vista, 7, 8, 8.1, 10, 11)
│       ├── Model/
│       │   ├── UpdateDuration.swift             # Short (~12s), Normal (~28s), Theatrical (~65s), Custom
│       │   ├── PersonalityIntensity.swift       # Authentic (Default), Subtle, Standard, HighVibes
│       │   ├── RareEvent.swift                  # Easter egg registry & canon line
│       │   ├── FakeUpdateItem.swift             # Generated KB items with sizes & components
│       │   ├── UpdateStage.swift                # Checking, downloading, verifying, installing, etc.
│       │   ├── UpdateStep.swift                 # Atomic procedural step model
│       │   ├── UpdateSession.swift              # Full deterministic blueprint
│       │   └── UpdateState.swift                # Observable runtime simulation state
│       ├── Engine/
│       │   ├── SplitMix64.swift                 # Fast, reproducible 64-bit PRNG
│       │   └── ProceduralUpdateEngine.swift     # Core procedural generation & pacing logic
│       ├── Content/
│       │   ├── ContentPools.swift               # Weighted flavor distributor
│       │   ├── SystemFilenames.swift            # Era-authentic DLLs, VXDs, INIs, SYS, CABs, paths
│       │   ├── TaskintoshContent.swift          # Mac ↔ Win bridges, vibe caches, wholesome lines
│       │   └── KBGenerator.swift                # Plausible historical KB generator
│       ├── Controller/
│       │   ├── FakeUpdateController.swift       # MainActor observable simulation manager
│       │   └── FakeUpdateIntegration.swift      # Drop-in entry points (`FakeUpdateSystem`)
│       ├── UI/
│       │   ├── Components/
│       │   │   ├── Classic3DBevel.swift         # Canonical GDI 2-tier bevels (#C0C0C0, #FFFFFF, #DFDFDF, #808080, #000000)
│       │   │   ├── ChunkyProgressBar.swift      # Segmented navy block progress bar with 0%, 1%, 50%, 99%, 100% guarantees
│       │   │   ├── AeroProgressBar.swift        # Glowing green/cyan glass progress bar
│       │   │   └── Spinners.swift               # Win10 Dotted & Win11 Fluent spinners
│       │   └── FakeUpdateWindowController.swift # AppKit NSWindowController wrapper with Esc intercept
│       └── Renderers/
│           ├── Win95UpdateRenderer.swift        # Compact 350x195 Win95/98/ME setup dialog
│           ├── WinXPUpdateRenderer.swift        # Windows XP Luna blue Automatic Updates wizard
│           ├── WinVistaUpdateRenderer.swift     # Windows Vista Aero dark glass
│           ├── Win7UpdateRenderer.swift         # Windows 7 iconic "Installing update X of Y"
│           ├── Win8UpdateRenderer.swift         # Windows 8 & 8.1 sparse modern full-bleed
│           ├── Win10UpdateRenderer.swift        # Windows 10 circular dotted spinner theater
│           ├── Win11UpdateRenderer.swift        # Windows 11 modern mica & fluid ring
│           └── FakeUpdateWindowView.swift       # Master renderer dispatcher (overlay-free for classic)
├── PreviewApp/
│   └── main.swift                               # Interactive macOS test app with clean screenshot mode
└── Tests/
    ├── TestRunner/main.swift                    # Command-line test suite runner (71 tests)
    └── ProceduralWindowsUpdateTests/            # Standard XCTest test suite for Xcode
```

---

## Progress Bar Math & Validation

`ChunkyProgressBar` strictly implements authentic Windows 95 integer floor scaling (`floor(progress * total)`):
- **Progress $\le 0$**: Exactly 0 filled blocks.
- **$0 < 	ext{Progress} < 1$**: Exactly $\lfloor 	ext{progress} 	imes 	ext{total} \rfloor$ filled blocks, with no forced 1% active block deviation.
- **50% Progress**: Exactly $\lfloor 	ext{total} 	imes 0.5 \rfloor$ filled blocks.
- **99% Progress**: Guaranteed $\le 	ext{total} - 1$ filled blocks, preventing premature completion appearances.
- **100% Progress / Progress $\ge 1$**: Exactly $100\%$ of block slots are filled (`total` blocks), reaching the inner right edge of the sunken trough with zero trailing gap.
- **Safety & Clamping**: Robust handling for NaN, infinity, negative, and invalid-width geometry, safely returning `(0, 0)`.

---

## Running Tests & Preview

### Run Automated Tests (71 Checks)
```bash
./scripts/run-tests.sh
```
All 71 assertions pass with 0 failures, verifying:
1. Deterministic seed reproduction.
2. Distinct seeds produce different sessions.
3. Default authentic mode strictly excludes comedic phrases and rare events.
4. Theatrical mode properly enables easter eggs and canon lines.
5. Progress bar clamping, 0%, 1%, 50%, 99%, and 100% completed-state math.
6. Classic dialog layout and state behavior across Win95, Win98, WinME.
7. All 10 supported Windows eras generate valid sessions.
8. Progress values remain strictly bounded within `[0.0, 1.0]`.
9. Short, Normal, and Theatrical duration scaling.
10. Controller lifecycle, Cancel, Esc, and single `onClose` callback invocation.

### Run Standalone Interactive Preview
```bash
./scripts/run-preview.sh
```
- Includes a **📷 Screenshot Mode** that displays only the period-accurate desktop background (`#008080`) and the floating dialog.
- No developer toolbar, no floating buttons, no overlays.
- Double-clicking the desktop canvas or pressing Tab toggles developer controls back on.
