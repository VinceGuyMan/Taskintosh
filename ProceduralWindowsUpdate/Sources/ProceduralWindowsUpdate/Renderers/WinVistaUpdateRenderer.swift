import SwiftUI
import AppKit

/// Procedural vector representation of the iconic Windows Vista Aero Security Shield.
private struct VistaShieldIcon: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Shield path
            var path = Path()
            path.move(to: CGPoint(x: 2, y: 2))
            path.addLine(to: CGPoint(x: w - 2, y: 2))
            path.addLine(to: CGPoint(x: w - 2, y: h * 0.58))
            path.addQuadCurve(to: CGPoint(x: w / 2, y: h - 1), control: CGPoint(x: w - 2, y: h * 0.88))
            path.addQuadCurve(to: CGPoint(x: 2, y: h * 0.58), control: CGPoint(x: 2, y: h * 0.88))
            path.closeSubpath()

            // Outer cyan glow
            context.stroke(path, with: .color(Color.cyan.opacity(0.7)), lineWidth: 2)

            // Inner dark base
            context.fill(path, with: .color(Color(red: 0.05, green: 0.1, blue: 0.18)))

            // 4 quadrant colors
            let midX = w / 2
            let midY = h * 0.44
            let r: CGFloat = 5.5

            // Red (top-left)
            context.fill(Path(CGRect(x: midX - r - 1, y: midY - r - 1, width: r, height: r)), with: .color(Color(red: 235/255, green: 65/255, blue: 45/255)))
            // Green (top-right)
            context.fill(Path(CGRect(x: midX + 1, y: midY - r - 1, width: r, height: r)), with: .color(Color(red: 60/255, green: 190/255, blue: 50/255)))
            // Blue (bottom-left)
            context.fill(Path(CGRect(x: midX - r - 1, y: midY + 1, width: r, height: r)), with: .color(Color(red: 0/255, green: 130/255, blue: 240/255)))
            // Yellow (bottom-right)
            context.fill(Path(CGRect(x: midX + 1, y: midY + 1, width: r, height: r)), with: .color(Color(red: 255/255, green: 210/255, blue: 30/255)))

            // Diagonal specular glass shine
            var shinePath = Path()
            shinePath.move(to: CGPoint(x: 3, y: 3))
            shinePath.addLine(to: CGPoint(x: w - 3, y: 3))
            shinePath.addLine(to: CGPoint(x: 3, y: h * 0.65))
            shinePath.closeSubpath()
            context.fill(shinePath, with: .color(Color.white.opacity(0.35)))
        }
        .frame(width: 32, height: 32)
    }
}

/// Authentic Windows Vista Aero glass-style button (75x23 pt).
public struct VistaButtonStyle: ButtonStyle {
    public var isDefault: Bool

    public init(isDefault: Bool = false) {
        self.isDefault = isDefault
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WinVistaUpdateRenderer.vistaFont(size: 11, weight: isDefault ? .semibold : .regular))
            .foregroundColor(.white)
            .frame(width: 75, height: 23)
            .background(
                Group {
                    if configuration.isPressed {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.06)
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
                            ? Color.cyan.opacity(0.8)
                            : Color.white.opacity(0.25),
                        lineWidth: 1
                    )
            )
            .shadow(color: isDefault ? Color.cyan.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 0)
    }
}

/// Windows Vista Aero Glass update renderer.
/// Accurately reproduces the dark translucent glass frame, subtle cyan glow,
/// Segoe UI typography, green Aero progress bar, and period-authentic layout.
public struct WinVistaUpdateRenderer: View {
    @ObservedObject public var controller: FakeUpdateController
    public var onClose: (() -> Void)?

    public init(controller: FakeUpdateController, onClose: (() -> Void)? = nil) {
        self.controller = controller
        self.onClose = onClose
    }

    /// Typography helper: prefers Segoe UI if available, falls back to system font.
    public static func vistaFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        #if canImport(AppKit)
        if NSFont(name: "Segoe UI", size: size) != nil {
            return .custom("Segoe UI", size: size)
        }
        #endif
        return .system(size: size, weight: weight, design: .default)
    }

    /// Semibold typography helper for Vista.
    public static func vistaSemiboldFont(size: CGFloat) -> Font {
        #if canImport(AppKit)
        if NSFont(name: "Segoe UI Semibold", size: size) != nil || NSFont(name: "Segoe UI", size: size) != nil {
            return .custom("Segoe UI Semibold", size: size)
        }
        #endif
        return .system(size: size, weight: .semibold, design: .default)
    }

    public var body: some View {
        let state = controller.state

        VStack(spacing: 0) {
            // 1. Aero Glass Title Bar (28pt)
            HStack {
                Text("Windows Update")
                    .font(Self.vistaSemiboldFont(size: 12))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.4), radius: 4, x: 0, y: 0)

                Spacer()

                // Vista Wide Aero Red Close Button (44x18 pt)
                Button(action: {
                    controller.cancel()
                    onClose?()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.90, green: 0.35, blue: 0.30, opacity: 0.85),
                                        Color(red: 0.80, green: 0.15, blue: 0.15, opacity: 0.90),
                                        Color(red: 0.60, green: 0.05, blue: 0.05, opacity: 0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                            )

                        Text("✕")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 18)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.15, blue: 0.22, opacity: 0.92),
                        Color(red: 0.05, green: 0.08, blue: 0.12, opacity: 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Top glass reflection line
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)

            // 2. Vista Body (248pt)
            VStack(alignment: .leading, spacing: 14) {
                // Header row with Vista Shield & Stage/Headline
                HStack(spacing: 12) {
                    VistaShieldIcon()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            state.status == .completed
                                ? "Updates successfully installed"
                                : (state.status == .cancelled
                                    ? "Installation Cancelled"
                                    : (state.status == .paused
                                        ? "Configuration Paused: Stage \(min(3, max(1, (state.currentStageIndex / 2) + 1))) of 3"
                                        : "Configuring updates: Stage \(min(3, max(1, (state.currentStageIndex / 2) + 1))) of 3"))
                        )
                        .font(Self.vistaSemiboldFont(size: 13))
                        .foregroundColor(.white)

                        Text(
                            state.status == .completed
                                ? "Windows Vista is up to date."
                                : (state.status == .cancelled
                                    ? "The update configuration was cancelled."
                                    : (state.status == .paused
                                        ? "Configuration is paused."
                                        : "Do not turn off your computer."))
                        )
                        .font(Self.vistaFont(size: 11))
                        .foregroundColor(Color.white.opacity(0.82))
                    }
                }

                // Progress Bar & Percentage
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(
                            state.status == .completed
                                ? "All updates applied successfully."
                                : (state.status == .cancelled
                                    ? "Process cancelled."
                                    : "Installing update \(state.currentUpdateNumber) of \(state.totalUpdateCount)...")
                        )
                        .font(Self.vistaFont(size: 11))
                        .foregroundColor(Color.white.opacity(0.9))
                        .lineLimit(1)

                        Spacer()

                        Text("\(state.percentageInt)%")
                            .font(Self.vistaSemiboldFont(size: 11))
                            .foregroundColor(.white)
                    }

                    AeroProgressBar(progress: state.overallProgress, isAnimated: state.status == .running)
                }

                // File updating status
                VStack(alignment: .leading, spacing: 3) {
                    Text("Status: \(state.currentMessage)")
                        .font(Self.vistaFont(size: 11))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)

                    if state.status != .completed, let path = state.currentPath, let file = state.currentFile {
                        Text("Updating: \(path)\(file)")
                            .font(Self.vistaFont(size: 10))
                            .foregroundColor(Color.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                // Theatrical Easter Egg (strictly opt-in via highVibes personality)
                if let event = state.activeRareEvent, controller.currentSession?.personality != .authentic {
                    HStack(spacing: 6) {
                        Text("✦")
                            .foregroundColor(.cyan)
                        Text(event.primaryMessage)
                            .font(Self.vistaFont(size: 10, weight: .medium))
                            .foregroundColor(.cyan)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(4)
                }

                Spacer()

                // 3. Footer area
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)

                HStack {
                    Spacer()

                    if state.status == .completed || state.status == .cancelled {
                        Button("Close") {
                            onClose?()
                        }
                        .buttonStyle(VistaButtonStyle(isDefault: true))
                    } else {
                        Button("Cancel") {
                            controller.cancel()
                            onClose?()
                        }
                        .buttonStyle(VistaButtonStyle(isDefault: false))
                    }
                }
                .padding(.top, 2)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.18, opacity: 0.95),
                        Color(red: 0.03, green: 0.05, blue: 0.08, opacity: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(width: 490, height: 320)
        .fixedSize()
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.55), Color.blue.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.cyan.opacity(0.25), radius: 10, x: 0, y: 0)
    }
}
