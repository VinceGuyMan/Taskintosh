# Legal, Trademark & Asset Strategy

Taskintosh is an independent, open-source macOS desktop utility. This document outlines the compliance policy, trademark considerations, and asset recreation guidelines for the project.

---

## 1. Clean-Room Asset Policy

Taskintosh **does not bundle, extract, or redistribute copyrighted Microsoft assets**, including but not limited to:
- Proprietary bitmaps, ICOs, DLLs, or EXE resource extracts from Microsoft Windows installations.
- Official trademarked logos (such as the Microsoft Windows 4-color wave/flag emblem).
- Proprietary sound files (such as Windows 95 startup/shutdown chimes composed by Brian Eno).
- Commercial fonts subject to restrictive licenses (such as Microsoft Sans Serif, Tahoma, or Segoe UI).

All visual assets included in the shipping repository and the default `Windows95.taskintosh-era` package are **original, clean-room recreations** created specifically for Taskintosh:

1. **Start Button Emblem**: An original, non-infringing 4-quadrant geometric emblem with primary color bevels that evokes mid-1990s desktop aesthetics without copying Microsoft's registered trademarks.
2. **Start Menu Banner**: Displays original retro branding text (*"Taskintosh 95"*), honoring the aesthetic layout without claiming trademark affiliation.
3. **Icons**: Vector SVGs and CoreGraphics procedural drawings created from scratch representing generic desktop concepts (folders, documents, sliders, magnifying glasses, CRT monitors).
4. **Typography**: Utilizes Apple's native system fonts (with configurable bitmap-style sizes and weights) or open-source typefaces.
5. **Sounds**: Audio playback hooks are architecture-ready, but no proprietary audio recordings are distributed.

---

## 2. Trademarks & Brand References

- **Taskintosh** is an original brand and parody/homage concept (*"The wrong taskbar for the right computer."*).
- References to historical operating systems (e.g., "Windows 95", "Windows XP", "Windows 7") are made solely for **nominative historical reference and compatibility identification** under fair use doctrine.
- Taskintosh is not affiliated with, endorsed by, or sponsored by Microsoft Corporation or Apple Inc.

---

## 3. Architecture Independence & Community Eras

A cornerstone of the Taskintosh architecture is the total separation between the application engine (`TaskintoshKit`) and Era configuration packages (`*.taskintosh-era`).

- **Engine Decoupling**: The engine code contains no proprietary references or hard-coded historical assets.
- **User Freedom**: Users and community creators may create their own custom Era packs for private use. Community authors who create Era packs are responsible for ensuring that their contributions adhere to applicable copyright and trademark laws in their respective jurisdictions.
- **Removable Packages**: Every Era package—including the built-in reference Era—can be inspected, modified, or removed from the filesystem at any time.

---

## 4. Contributing Guidelines

Contributors to Taskintosh must adhere to the following rules:
- **No Resource Dumps**: PRs containing extracted binaries, proprietary `.wav` sound files, or extracted `.ico` files from commercial operating systems will be rejected immediately.
- **Vector & Procedural Preference**: Prefer vector (SVG) drawings or procedural CoreGraphics code for all visual elements.
- **Originality**: Ensure all submitted artwork, icons, and themes are either your original work or released under permissive open-source licenses (MIT, Apache 2.0, CC0).
