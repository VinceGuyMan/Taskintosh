import SwiftUI

/// Title bar icon mode for the classic dialog renderer.
public enum ClassicTitleBarIcon: String, CaseIterable, Equatable, Sendable {
    /// Canonical Win32 setup dialog standard: no icon in title bar, flush left title text.
    case none
    /// Period-appropriate setup diskette and computer icon.
    case setupMonitor
    /// Historical 4-color Windows flag emblem.
    case windowsFlag
}

/// Period-appropriate 14x14 PC monitor and setup disk icon.
private struct SetupMonitorIcon: View {
    var body: some View {
        Canvas { context, size in
            // Outer monitor frame: 13x11 px at (0, 0)
            let monitorFrame = CGRect(x: 0, y: 0, width: 13, height: 10)
            context.fill(Path(monitorFrame), with: .color(Color(red: 192/255, green: 192/255, blue: 192/255)))
            context.stroke(Path(monitorFrame), with: .color(.black), lineWidth: 1)

            // Inner monitor screen: 9x6 px at (2, 2)
            let screenRect = CGRect(x: 2, y: 2, width: 9, height: 6)
            context.fill(Path(screenRect), with: .color(Color(red: 0.0, green: 128/255, blue: 128/255)))

            // Stand: 5x2 px at (4, 10)
            let standRect = CGRect(x: 4, y: 10, width: 5, height: 2)
            context.fill(Path(standRect), with: .color(Color(red: 128/255, green: 128/255, blue: 128/255)))

            // Base: 9x1 px at (2, 12)
            let baseRect = CGRect(x: 2, y: 12, width: 9, height: 1)
            context.fill(Path(baseRect), with: .color(.black))
        }
        .frame(width: 14, height: 14)
    }
}

/// Pixel-crisp 14x14 classic 4-color Windows flag icon.
private struct WindowsSetupIcon: View {
    var body: some View {
        Canvas { context, size in
            let rRect = CGRect(x: 1, y: 1, width: 5, height: 5)
            let gRect = CGRect(x: 7, y: 1, width: 5, height: 5)
            let bRect = CGRect(x: 1, y: 7, width: 5, height: 5)
            let yRect = CGRect(x: 7, y: 7, width: 5, height: 5)

            context.fill(Path(rRect), with: .color(Color(red: 220/255, green: 40/255, blue: 30/255)))
            context.fill(Path(gRect), with: .color(Color(red: 50/255, green: 170/255, blue: 60/255)))
            context.fill(Path(bRect), with: .color(Color(red: 30/255, green: 100/255, blue: 210/255)))
            context.fill(Path(yRect), with: .color(Color(red: 245/255, green: 200/255, blue: 40/255)))
        }
        .frame(width: 14, height: 14)
    }
}

/// Pixel-accurate classic Windows 95 close button "✕" glyph (canonical 8x7 Marlett bitmap).
private struct ClassicCloseGlyph: View {
    var body: some View {
        Canvas { context, size in
            // Canonical Windows 95 8x7 pixel close glyph coordinates centered in 16x14 button:
            // x: 4 to 11, y: 3 to 9
            let points: [(Int, Int)] = [
                // Row 0 (y=3): x=4,5 and 10,11
                (4, 3), (5, 3), (10, 3), (11, 3),
                // Row 1 (y=4): x=5,6 and 9,10
                (5, 4), (6, 4), (9, 4), (10, 4),
                // Row 2 (y=5): x=6,7,8,9
                (6, 5), (7, 5), (8, 5), (9, 5),
                // Row 3 (y=6): x=7,8
                (7, 6), (8, 6),
                // Row 4 (y=7): x=6,7,8,9
                (6, 7), (7, 7), (8, 7), (9, 7),
                // Row 5 (y=8): x=5,6 and 9,10
                (5, 8), (6, 8), (9, 8), (10, 8),
                // Row 6 (y=9): x=4,5 and 10,11
                (4, 9), (5, 9), (10, 9), (11, 9)
            ]

            for (px, py) in points {
                context.fill(Path(CGRect(x: px, y: py, width: 1, height: 1)), with: .color(.black))
            }
        }
        .frame(width: 16, height: 14)
    }
}

/// Authentic Windows 95/98 push button style with pressed depression state.
public struct ClassicButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.black)
            .frame(width: 75, height: 23)
            .background(Color(red: 192/255, green: 192/255, blue: 192/255))
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
            .classicBevel(.button(isPressed: configuration.isPressed))
    }
}

/// Authentic Windows 95/98 title-bar close button style with pressed state.
private struct ClassicCloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 16, height: 14)
            .background(Color(red: 192/255, green: 192/255, blue: 192/255))
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
            .classicBevel(.button(isPressed: configuration.isPressed))
    }
}

/// Faithful Windows 95 / 98 / ME era update and setup dialog renderer.
/// Matches the exact dimensions, colors, bevels, typography, and layout of authentic Win32 dialogs.
public struct Win95UpdateRenderer: View {
    @ObservedObject public var controller: FakeUpdateController
    public var onClose: (() -> Void)?
    public var titleBarIcon: ClassicTitleBarIcon

    public init(
        controller: FakeUpdateController,
        titleBarIcon: ClassicTitleBarIcon = .none,
        onClose: (() -> Void)? = nil
    ) {
        self.controller = controller
        self.titleBarIcon = titleBarIcon
        self.onClose = onClose
    }

    /// Title bar headline tailored across 95, 98, ME
    private var titleText: String {
        switch controller.activeEra {
        case .win95:
            return "Windows 95 Update"
        case .win98:
            return "Windows 98 Update"
        case .winME:
            return "Windows Millennium Edition Update"
        default:
            return "\(controller.activeEra.rawValue) Update"
        }
    }

    /// Prompt header line
    private var promptText: String {
        if controller.state.status == .completed {
            return "Windows has finished updating your system files."
        }
        switch controller.activeEra {
        case .win95:
            return "Windows is updating the following files:"
        case .win98:
            return "Windows is updating your system files:"
        case .winME:
            return "Please wait while Setup updates your system."
        default:
            return "Windows is updating your system files:"
        }
    }

    /// Operation or copying status line
    private var operationLine: String {
        if controller.state.status == .completed {
            return "Setup is complete."
        }
        if let path = controller.state.currentPath, let file = controller.state.currentFile {
            return "\(path)\(file)"
        }
        return controller.state.currentMessage
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Title Bar (Strict 18px height, solid Navy #000080)
            HStack(spacing: 4) {
                switch titleBarIcon {
                case .none:
                    EmptyView()
                case .setupMonitor:
                    SetupMonitorIcon()
                        .padding(.leading, 3)
                case .windowsFlag:
                    WindowsSetupIcon()
                        .padding(.leading, 3)
                }

                Text(titleText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.leading, titleBarIcon == .none ? 4 : 2)

                Spacer()

                // Classic Close Button (16x14 px, 2px right inset)
                Button(action: {
                    controller.cancel()
                    onClose?()
                }) {
                    ClassicCloseGlyph()
                }
                .buttonStyle(ClassicCloseButtonStyle())
                .padding(.trailing, 2)
            }
            .frame(height: 18)
            .background(Color(red: 0.0, green: 0.0, blue: 128/255)) // Canonical Navy #000080
            .padding(.horizontal, 2)
            .padding(.top, 2)

            // Dialog Body Content Area (Dense, compact, authentic spacing)
            VStack(alignment: .leading, spacing: 8) {
                // Prompt Text
                Text(promptText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.black)
                    .lineLimit(1)

                // Copying / Operation section
                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.state.status == .completed ? "Status:" : "Copying file:")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.black)

                    Text(operationLine)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 34, alignment: .topLeading)

                // Recessed Segmented Progress Bar (16px height)
                ChunkyProgressBar(
                    progress: controller.state.overallProgress,
                    isAnimated: controller.state.status == .running,
                    isMarquee: controller.state.status == .running && controller.state.overallProgress < 0.05
                )
                .frame(height: 16)

                Spacer(minLength: 6)

                // Footer with a single authentic Cancel/OK button
                HStack {
                    Spacer()

                    Button(action: {
                        if controller.state.status == .completed {
                            onClose?()
                        } else {
                            controller.cancel()
                            onClose?()
                        }
                    }) {
                        Text(controller.state.status == .completed ? "OK" : "Cancel")
                    }
                    .buttonStyle(ClassicButtonStyle())
                }
            }
            .padding(10)
            .background(Color(red: 192/255, green: 192/255, blue: 192/255))
        }
        .background(Color(red: 192/255, green: 192/255, blue: 192/255))
        .classicBevel(.windowFrame)
        .frame(width: 350, height: 195)
        .fixedSize()
    }
}
