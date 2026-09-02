# Taskintosh Era Specification (v1.0)

This document defines the **Taskintosh Era Package Specification** (`.taskintosh-era`).

An **Era** is a standalone, installable bundle that completely defines the visual design, geometric layout, and interaction behavior of a desktop era. Community developers, designers, and enthusiasts can create custom Eras without modifying Taskintosh source code or recompiling the application.

---

## 1. Package Structure

An Era is packaged as a macOS directory bundle with the `.taskintosh-era` file extension:

```
MyCustomEra.taskintosh-era/
├── manifest.json       (Required) Package identity, author, and version
├── layout.json         (Optional) Geometry, height, spacing, and button metrics
├── theme.json          (Optional) Color palette, bevel styles, and typography
├── behaviors.json      (Optional) Auto-hide, window grouping, and click rules
└── assets/             (Optional) Custom vector or bitmap icons
    ├── start_emblem.svg
    ├── programs.svg
    ├── documents.svg
    ├── settings.svg
    ├── find.svg
    ├── help.svg
    ├── run.svg
    ├── shutdown.svg
    └── sound.svg
```

---

## 2. Configuration Schemas

### `manifest.json` (Required)
Defines the identity and metadata of the Era.

```json
{
  "id": "org.community.era.win98",
  "name": "Windows 98 Classic",
  "version": "1.0.0",
  "author": "Desktop Historian",
  "eraPeriod": "1998-2000",
  "description": "Windows 98 desktop taskbar with QuickLaunch bar and gradient Start banner.",
  "minEngineVersion": "1.0.0"
}
```

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique reverse-DNS identifier (e.g., `com.author.era.name`) |
| `name` | String | Display name shown in Era Manager |
| `version` | String | Semantic version string (e.g., `1.0.0`) |
| `author` | String | Author name or organization |
| `eraPeriod` | String | Historical timeframe represented (e.g., `1995-1998`) |
| `description`| String | Short summary of the Era's aesthetic and features |
| `minEngineVersion` | String | Minimum supported Taskintosh engine version |

---

### `layout.json` (Optional)
Controls physical sizing, margins, and taskbar placement.

```json
{
  "defaultEdge": "bottom",
  "taskbarHeight": 28,
  "itemSpacing": 2,
  "paddingHorizontal": 2,
  "paddingVertical": 2,
  "startButtonWidth": 54,
  "startButtonHeight": 22,
  "taskButtonMinWidth": 40,
  "taskButtonMaxWidth": 160,
  "trayPadding": 3
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `defaultEdge` | String | `"bottom"` | Screen edge: `"bottom"`, `"top"`, `"left"`, or `"right"` |
| `taskbarHeight` | Number | `28` | Height in screen points (or width for left/right edges) |
| `itemSpacing` | Number | `2` | Horizontal spacing between adjacent task buttons |
| `paddingHorizontal` | Number | `2` | Padding between the screen edge and the Start button |
| `paddingVertical` | Number | `2` | Vertical margin inside the taskbar |
| `startButtonWidth` | Number | `54` | Width allocated for the Start button |
| `startButtonHeight` | Number | `null` | Optional height override for the Start button |
| `taskButtonMinWidth` | Number | `40` | Minimum button width when many apps are open |
| `taskButtonMaxWidth` | Number | `160` | Maximum button width when few apps are open |
| `trayPadding` | Number | `3` | Internal padding around system tray items |

---

### `theme.json` (Optional)
Defines the color palette, bevel borders, and typography.

```json
{
  "backgroundColorHex": "#C0C0C0",
  "surfaceColorHex": "#C0C0C0",
  "lightHighlightColorHex": "#FFFFFF",
  "shadowColorHex": "#808080",
  "darkShadowColorHex": "#000000",
  "textColorHex": "#000000",
  "activeTextColorHex": "#000000",
  "bannerStartColorHex": "#000080",
  "bannerEndColorHex": "#1084D0",
  "accentColorHex": "#000080",
  "bevelStyle": "classic3D",
  "ditherActiveButton": true,
  "fontSize": 11,
  "fontName": null,
  "startButtonText": "Start",
  "bannerText": "Taskintosh 95"
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `backgroundColorHex` | Hex Color | `"#C0C0C0"` | Overall taskbar background |
| `surfaceColorHex` | Hex Color | `"#C0C0C0"` | Button and panel surface color |
| `lightHighlightColorHex` | Hex Color | `"#FFFFFF"` | Top/left 3D highlight edge |
| `shadowColorHex` | Hex Color | `"#808080"` | Inner bottom/right 3D shadow edge |
| `darkShadowColorHex` | Hex Color | `"#000000"` | Outer bottom/right 3D shadow edge |
| `textColorHex` | Hex Color | `"#000000"` | Normal button and menu text color |
| `activeTextColorHex` | Hex Color | `"#000000"` | Focused button text color |
| `bannerStartColorHex` | Hex Color | `"#000080"` | Bottom color of the vertical Start banner |
| `bannerEndColorHex` | Hex Color | `"#1084D0"` | Top color of the vertical Start banner |
| `accentColorHex` | Hex Color | `"#000080"` | Menu item selection highlight color |
| `bevelStyle` | String | `"classic3D"` | Bevel algorithm: `"classic3D"`, `"flat"`, or `"etched"` |
| `ditherActiveButton` | Boolean | `true` | Enables 50% checkerboard dither on active buttons |
| `fontSize` | Number | `11` | Default label font size in points |
| `fontName` | String? | `null` | Optional PostScript font family name (system fallback if null) |
| `startButtonText` | String | `"Start"` | Text label displayed on the Start button |
| `bannerText` | String | `"Taskintosh 95"` | Text rendered along the vertical Start menu banner |

---

### `behaviors.json` (Optional)
Controls interaction rules and state transitions.

```json
{
  "autoHideSupported": true,
  "autoHideDelaySeconds": 0.5,
  "autoHidePeekMargin": 2.0,
  "clickActiveAppAction": "minimize",
  "windowGrouping": "none",
  "soundEffectsEnabled": false
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `autoHideSupported` | Boolean | `true` | Whether auto-hide can be toggled in this Era |
| `autoHideDelaySeconds`| Number | `0.5` | Delay in seconds before sliding off-screen |
| `autoHidePeekMargin` | Number | `2.0` | Pixels left exposed along the screen edge when hidden |
| `clickActiveAppAction` | String | `"minimize"` | Action when clicking already active app: `"minimize"` or `"none"` |
| `windowGrouping` | String | `"none"` | Task button grouping policy: `"none"`, `"groupWhenFull"`, or `"alwaysGroup"` |
| `soundEffectsEnabled` | Boolean | `false` | Whether audio feedback hooks are enabled |

---

## 3. Asset Specifications

Assets are placed in the `assets/` subfolder. Supported formats are **SVG** (recommended for sharpness on Retina displays), **PNG**, and **PDF**.

| Asset Name | Resolution | Description |
|---|---|---|
| `start_emblem` | 16x16 px | Icon placed to the left of "Start" on the Start button |
| `programs` | 24x24 px | Start menu Programs folder icon |
| `documents` | 24x24 px | Start menu Documents icon |
| `settings` | 24x24 px | Start menu Settings icon |
| `find` | 24x24 px | Start menu Find/Search icon |
| `help` | 24x24 px | Start menu Help icon |
| `run` | 24x24 px | Start menu Run... icon |
| `shutdown` | 24x24 px | Start menu Shut Down icon |
| `sound` | 16x16 px | System tray audio speaker indicator |

If an asset file is not provided in the pack, Taskintosh uses its built-in procedural graphics generator as a fallback.

---

## 4. How to Create and Test a New Era

1. Create a new folder named `Windows2000.taskintosh-era`.
2. Create `manifest.json` with your metadata:
   ```json
   {
     "id": "com.user.era.win2000",
     "name": "Windows 2000 Professional",
     "version": "1.0.0",
     "author": "User",
     "eraPeriod": "1999-2001",
     "description": "Clean, understated professional desktop theme.",
     "minEngineVersion": "1.0.0"
   }
   ```
3. Create `theme.json` with customized colors and banner text:
   ```json
   {
     "bannerText": "Taskintosh 2000",
     "bannerStartColorHex": "#0A246A",
     "bannerEndColorHex": "#A6CAF0"
   }
   ```
4. In Taskintosh, open the **Era Manager** (from the tray icon, Start Menu -> Settings, or taskbar right-click).
5. Click **Import Era...** and select your `Windows2000.taskintosh-era` folder.
6. Click **Activate Era**. Taskintosh will immediately re-render with your custom era settings!
