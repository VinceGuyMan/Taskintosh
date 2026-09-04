import SwiftUI
import AppKit

/// Procedural pixel-accurate 16x16 Windows XP Automatic Updates shield icon.
private struct LunaShieldIcon: View {
    var body: some View {
        Canvas { context, size in
            // Shield outer border (Gold #CCA000 / Navy #002266)
            let w = size.width
            let h = size.height

            // Outer shield shape
            var path = Path()
            path.move(to: CGPoint(x: 2, y: 1))
            path.addLine(to: CGPoint(x: w - 2, y: 1))
            path.addLine(to: CGPoint(x: w - 2, y: h * 0.55))
            path.addQuadCurve(to: CGPoint(x: w / 2, y: h - 1), control: CGPoint(x: w - 2, y: h * 0.85))
            path.addQuadCurve(to: CGPoint(x: 2, y: h * 0.55), control: CGPoint(x: 2, y: h * 0.85))
            path.closeSubpath()

            // Gold fill
            context.fill(path, with: .color(Color(red: 245/255, green: 195/255, blue: 30/255)))
            context.stroke(path, with: .color(Color(red: 0/255, green: 40/255, blue: 130/255)), lineWidth: 1.2)

            // 4 quadrant Windows colors in center
            let midX = w / 2
            let midY = h * 0.42
            let r: CGFloat = 3.2

            // Red (top-left)
            context.fill(Path(CGRect(x: midX - r - 0.5, y: midY - r - 0.5, width: r, height: r)), with: .color(Color(red: 230/255, green: 55/255, blue: 35/255)))
            // Green (top-right)
            context.fill(Path(CGRect(x: midX + 0.5, y: midY - r - 0.5, width: r, height: r)), with: .color(Color(red: 70/255, green: 180/255, blue: 45/255)))
            // Blue (bottom-left)
            context.fill(Path(CGRect(x: midX - r - 0.5, y: midY + 0.5, width: r, height: r)), with: .color(Color(red: 30/255, green: 110/255, blue: 215/255)))
            // Yellow (bottom-right)
            context.fill(Path(CGRect(x: midX + 0.5, y: midY + 0.5, width: r, height: r)), with: .color(Color(red: 250/255, green: 205/255, blue: 40/255)))
        }
        .frame(width: 16, height: 16)
    }
}

/// Procedural retro CRT computer setup graphic for Windows XP Wizard 97 banner.
private struct LunaSetupHardwareGraphic: View {
    var body: some View {
        Canvas { context, size in
            // CRT Monitor (Left)
            let monitorRect = CGRect(x: 2, y: 3, width: 22, height: 19)
            context.fill(Path(monitorRect), with: .color(Color(red: 225/255, green: 222/255, blue: 210/255)))
            context.stroke(Path(monitorRect), with: .color(Color(red: 140/255, green: 135/255, blue: 120/255)), lineWidth: 1)

            // CRT Screen (Dark Blue with glow)
            let screenRect = CGRect(x: 4, y: 5, width: 18, height: 13)
            context.fill(Path(screenRect), with: .color(Color(red: 20/255, green: 65/255, blue: 140/255)))

            // Monitor stand
            let standRect = CGRect(x: 9, y: 22, width: 8, height: 4)
            context.fill(Path(standRect), with: .color(Color(red: 190/255, green: 185/255, blue: 175/255)))

            let baseRect = CGRect(x: 6, y: 26, width: 14, height: 3)
            context.fill(Path(baseRect), with: .color(Color(red: 170/255, green: 165/255, blue: 155/255)))

            // Tower Case (Right)
            let towerRect = CGRect(x: 27, y: 5, width: 9, height: 24)
            context.fill(Path(towerRect), with: .color(Color(red: 225/255, green: 222/255, blue: 210/255)))
            context.stroke(Path(towerRect), with: .color(Color(red: 140/255, green: 135/255, blue: 120/255)), lineWidth: 1)

            // CD-ROM drive bays
            context.fill(Path(CGRect(x: 29, y: 7, width: 5, height: 2)), with: .color(Color(red: 180/255, green: 175/255, blue: 165/255)))
            context.fill(Path(CGRect(x: 29, y: 10, width: 5, height: 2)), with: .color(Color(red: 180/255, green: 175/255, blue: 165/255)))

            // Power button LED (Green #30D030)
            context.fill(Path(CGRect(x: 30, y: 22, width: 2, height: 2)), with: .color(Color(red: 48/255, green: 208/255, blue: 48/255)))
        }
        .frame(width: 38, height: 32)
    }
}

/// Authentic Windows XP Luna-style push button (75x23 pt) with default focus ring option.
public struct LunaButtonStyle: ButtonStyle {
    public var isDefault: Bool

    public init(isDefault: Bool = false) {
        self.isDefault = isDefault
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WinXPUpdateRenderer.xpFont(size: 11, weight: isDefault ? .semibold : .regular))
            .foregroundColor(.black)
            .frame(width: 75, height: 23)
            .background(
                Group {
                    if configuration.isPressed {
                        LinearGradient(
                            colors: [
                                Color(red: 210/255, green: 205/255, blue: 188/255),
                                Color(red: 225/255, green: 220/255, blue: 205/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 242/255, green: 238/255, blue: 224/255),
                                Color(red: 225/255, green: 220/255, blue: 205/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        isDefault
                            ? Color(red: 0.05, green: 0.35, blue: 0.75)
                            : Color(red: 0.0, green: 0.24, blue: 0.46),
                        lineWidth: isDefault ? 1.5 : 1
                    )
            )
    }
}

/// Windows XP Luna-themed Automatic Updates wizard renderer.
/// Accurately reproduces the period-authentic Wizard 97 layout, Luna Blue titlebar,
/// Tahoma typography, green Luna progress bar, and wizard button semantics.
public struct WinXPUpdateRenderer: View {
    @ObservedObject public var controller: FakeUpdateController
    public var onClose: (() -> Void)?

    public init(controller: FakeUpdateController, onClose: (() -> Void)? = nil) {
        self.controller = controller
        self.onClose = onClose
    }

    /// Typography helper: prefers Tahoma if available on system, otherwise falls back to system font.
    public static func xpFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        #if canImport(AppKit)
        if NSFont(name: "Tahoma", size: size) != nil {
            return .custom("Tahoma", size: size)
        }
        #endif
        return .system(size: size, weight: weight)
    }

    /// Bold typography helper for Tahoma.
    public static func xpBoldFont(size: CGFloat) -> Font {
        #if canImport(AppKit)
        if NSFont(name: "Tahoma-Bold", size: size) != nil {
            return .custom("Tahoma-Bold", size: size)
        }
        #endif
        return .system(size: size, weight: .bold)
    }

    public var body: some View {
        let state = controller.state

        VStack(spacing: 0) {
            // 1. XP Luna Blue Title Bar (26pt)
            HStack(spacing: 6) {
                LunaShieldIcon()
                    .padding(.leading, 6)

                Text("Automatic Updates")
                    .font(Self.xpBoldFont(size: 11))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.0, green: 0.1, blue: 0.38), radius: 0.8, x: 1, y: 1)

                Spacer()

                // XP Close Button (21x21 pt red square with rounded corners)
                Button(action: {
                    controller.cancel()
                    onClose?()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 235/255, green: 96/255, blue: 70/255),  // Top highlight #EB6046
                                        Color(red: 216/255, green: 55/255, blue: 28/255),  // Mid #D8371C
                                        Color(red: 167/255, green: 24/255, blue: 0/255)    // Base #A71800
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                            )

                        Text("✕")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 21, height: 21)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .frame(height: 26)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.33, blue: 0.92), // Luna Blue highlight #0054EA
                        Color(red: 0.0, green: 0.22, blue: 0.85),
                        Color(red: 0.0, green: 0.15, blue: 0.70)  // Deep Luna blue base
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // 2. Wizard Header Sub-Banner (58pt)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.status == .completed ? "Updates Completed" : (state.status == .cancelled ? "Installation Cancelled" : "Installing Updates"))
                        .font(Self.xpBoldFont(size: 12))
                        .foregroundColor(.black)

                    Text(state.status == .completed ? "Windows XP has finished installing updates." : (state.status == .cancelled ? "The update installation was cancelled." : "Please wait while updates are installed on your computer."))
                        .font(Self.xpFont(size: 11))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .lineLimit(1)
                }
                Spacer()
                LunaSetupHardwareGraphic()
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(Color.white)

            // Etched divider line below banner
            Rectangle()
                .fill(Color(red: 160/255, green: 160/255, blue: 160/255))
                .frame(height: 1)
            Rectangle()
                .fill(Color.white)
                .frame(height: 1)

            // 3. Wizard Content Body (222pt)
            VStack(alignment: .leading, spacing: 12) {
                // Update tracker headline
                Text(
                    state.status == .completed
                        ? "All updates have been successfully installed."
                        : (state.status == .cancelled
                            ? "Update installation was cancelled before completion."
                            : (state.status == .paused
                                ? "Installation paused: update \(state.currentUpdateNumber) of \(state.totalUpdateCount)"
                                : "Installing update \(state.currentUpdateNumber) of \(state.totalUpdateCount)..."))
                )
                .font(Self.xpBoldFont(size: 11))
                .foregroundColor(.black)
                .lineLimit(1)

                // Package details line
                if state.status == .completed {
                    Text("Click Finish to close this wizard.")
                        .font(Self.xpFont(size: 11))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                } else if let kb = state.currentKB {
                    Text("Package: Security Update for Windows XP (\(kb))")
                        .font(Self.xpFont(size: 11))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .lineLimit(1)
                }

                // Authentic Windows XP Luna green segmented progress bar
                LunaProgressBar(progress: state.overallProgress, isAnimated: state.status == .running)

                HStack {
                    Text(state.status == .completed ? "100% complete" : "\(state.percentageInt)% complete")
                        .font(Self.xpFont(size: 11))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    Spacer()
                }

                // Recessed file / status info box
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.status == .completed ? "The installation process has completed successfully." : state.currentMessage)
                        .font(Self.xpFont(size: 11))
                        .foregroundColor(.black)
                        .lineLimit(2)

                    if state.status != .completed, let file = state.currentFile {
                        Text("Copying: \(file)")
                            .font(Self.xpFont(size: 10))
                            .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.35))
                            .lineLimit(1)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 127/255, green: 157/255, blue: 185/255), lineWidth: 1)
                )

                // Theatrical Easter Egg (strictly opt-in via highVibes personality)
                if let event = state.activeRareEvent, controller.currentSession?.personality != .authentic {
                    HStack(spacing: 6) {
                        Text("✦")
                            .font(Self.xpBoldFont(size: 10))
                            .foregroundColor(Color(red: 0.0, green: 0.3, blue: 0.7))
                        Text(event.primaryMessage)
                            .font(Self.xpFont(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.0, green: 0.25, blue: 0.6))
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.90, green: 0.94, blue: 1.0))
                    .cornerRadius(2)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .background(Color(red: 236/255, green: 233/255, blue: 216/255)) // Canonical Luna Dialog Face #ECE9D8

            // Etched divider line above footer
            Rectangle()
                .fill(Color(red: 160/255, green: 160/255, blue: 160/255))
                .frame(height: 1)
            Rectangle()
                .fill(Color.white)
                .frame(height: 1)

            // 4. Wizard Footer (40pt)
            HStack {
                Spacer()

                if state.status == .completed {
                    Button("Finish") {
                        onClose?()
                    }
                    .buttonStyle(LunaButtonStyle(isDefault: true))
                } else {
                    Button("Cancel") {
                        controller.cancel()
                        onClose?()
                    }
                    .buttonStyle(LunaButtonStyle(isDefault: false))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color(red: 236/255, green: 233/255, blue: 216/255))
        }
        .frame(width: 480, height: 350)
        .fixedSize()
        .background(Color(red: 236/255, green: 233/255, blue: 216/255))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.0, green: 0.33, blue: 0.92),
                            Color(red: 0.0, green: 0.18, blue: 0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
