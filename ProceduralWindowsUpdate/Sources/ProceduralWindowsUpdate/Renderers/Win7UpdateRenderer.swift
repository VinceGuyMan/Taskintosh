import SwiftUI
import AppKit

/// Procedural vector illustration of the iconic 3D Windows 7 Aero Flag Orb.
private struct Win7FlagOrb: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let radius: CGFloat = min(w, h) / 2.0 - 2.0

            // 1. Outer Radial Glow
            let outerGlowRect = CGRect(x: 0, y: 0, width: w, height: h)
            context.fill(
                Path(ellipseIn: outerGlowRect),
                with: .radialGradient(
                    Gradient(colors: [Color.cyan.opacity(0.35), Color.clear]),
                    center: center,
                    startRadius: radius * 0.4,
                    endRadius: radius * 1.15
                )
            )

            // 2. Glass Orb Sphere
            let sphereRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let spherePath = Path(ellipseIn: sphereRect)

            // Deep blue-cyan orb interior
            context.fill(
                spherePath,
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.12, green: 0.35, blue: 0.65, opacity: 0.90),
                        Color(red: 0.04, green: 0.14, blue: 0.32, opacity: 0.95),
                        Color(red: 0.01, green: 0.06, blue: 0.18, opacity: 0.98)
                    ]),
                    center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.3),
                    startRadius: 2,
                    endRadius: radius
                )
            )

            // Glass rim stroke
            context.stroke(
                spherePath,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.65), Color.cyan.opacity(0.4), Color.blue.opacity(0.2)]),
                    startPoint: CGPoint(x: sphereRect.minX, y: sphereRect.minY),
                    endPoint: CGPoint(x: sphereRect.maxX, y: sphereRect.maxY)
                ),
                lineWidth: 1.5
            )

            // 3. Four-Quadrant Wavy Windows 7 Flag
            let fw = radius * 0.52
            let fh = radius * 0.48
            let fx = center.x - fw / 2.0
            let fy = center.y - fh / 2.0

            // Red (Top-Left)
            var redPath = Path()
            redPath.move(to: CGPoint(x: fx, y: fy + 1))
            redPath.addQuadCurve(to: CGPoint(x: fx + fw * 0.46, y: fy), control: CGPoint(x: fx + fw * 0.22, y: fy - 1.5))
            redPath.addLine(to: CGPoint(x: fx + fw * 0.46, y: fy + fh * 0.46))
            redPath.addQuadCurve(to: CGPoint(x: fx, y: fy + fh * 0.47), control: CGPoint(x: fx + fw * 0.22, y: fy + fh * 0.45))
            redPath.closeSubpath()
            context.fill(redPath, with: .color(Color(red: 235/255, green: 60/255, blue: 40/255)))

            // Green (Top-Right)
            var greenPath = Path()
            greenPath.move(to: CGPoint(x: fx + fw * 0.54, y: fy))
            greenPath.addQuadCurve(to: CGPoint(x: fx + fw, y: fy - 0.5), control: CGPoint(x: fx + fw * 0.78, y: fy - 1.5))
            greenPath.addLine(to: CGPoint(x: fx + fw, y: fy + fh * 0.46))
            greenPath.addQuadCurve(to: CGPoint(x: fx + fw * 0.54, y: fy + fh * 0.46), control: CGPoint(x: fx + fw * 0.78, y: fy + fh * 0.45))
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(Color(red: 65/255, green: 185/255, blue: 50/255)))

            // Blue (Bottom-Left)
            var bluePath = Path()
            bluePath.move(to: CGPoint(x: fx, y: fy + fh * 0.54))
            bluePath.addQuadCurve(to: CGPoint(x: fx + fw * 0.46, y: fy + fh * 0.54), control: CGPoint(x: fx + fw * 0.22, y: fy + fh * 0.52))
            bluePath.addLine(to: CGPoint(x: fx + fw * 0.46, y: fy + fh))
            bluePath.addQuadCurve(to: CGPoint(x: fx, y: fy + fh + 1), control: CGPoint(x: fx + fw * 0.22, y: fy + fh - 0.5))
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(Color(red: 0/255, green: 130/255, blue: 240/255)))

            // Yellow (Bottom-Right)
            var yellowPath = Path()
            yellowPath.move(to: CGPoint(x: fx + fw * 0.54, y: fy + fh * 0.54))
            yellowPath.addQuadCurve(to: CGPoint(x: fx + fw, y: fy + fh * 0.54), control: CGPoint(x: fx + fw * 0.78, y: fy + fh * 0.52))
            yellowPath.addLine(to: CGPoint(x: fx + fw, y: fy + fh - 0.5))
            yellowPath.addQuadCurve(to: CGPoint(x: fx + fw * 0.54, y: fy + fh), control: CGPoint(x: fx + fw * 0.78, y: fy + fh - 0.5))
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(Color(red: 255/255, green: 210/255, blue: 30/255)))

            // 4. Specular Top Glass Highlight
            var glossPath = Path()
            glossPath.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y - radius * 0.4))
            glossPath.addQuadCurve(to: CGPoint(x: center.x + radius * 0.7, y: center.y - radius * 0.4), control: CGPoint(x: center.x, y: center.y - radius * 0.85))
            glossPath.addQuadCurve(to: CGPoint(x: center.x - radius * 0.7, y: center.y - radius * 0.4), control: CGPoint(x: center.x, y: center.y - radius * 0.15))
            glossPath.closeSubpath()
            context.fill(glossPath, with: .color(Color.white.opacity(0.38)))
        }
        .frame(width: 72, height: 72)
    }
}

/// Windows 7 Blue Theater Update Renderer.
/// Accurately renders the deep atmospheric royal blue update screen, 3D Aero flag orb,
/// Segoe UI light typography, glowing green Aero progress bar, and authentic state actions.
public struct Win7UpdateRenderer: View {
    @ObservedObject public var controller: FakeUpdateController
    public var onClose: (() -> Void)?

    public init(controller: FakeUpdateController, onClose: (() -> Void)? = nil) {
        self.controller = controller
        self.onClose = onClose
    }

    /// Typography helper: prefers Segoe UI if available, falls back to system font.
    public static func segoeFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        #if canImport(AppKit)
        if NSFont(name: "Segoe UI", size: size) != nil {
            return .custom("Segoe UI", size: size)
        }
        #endif
        return .system(size: size, weight: weight, design: .default)
    }

    public var body: some View {
        let state = controller.state

        ZStack {
            // 1. Windows 7 Deep Atmospheric Blue Background with Radial Vignette
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.24, blue: 0.48), // Center luminous blue #143D7A
                    Color(red: 0.03, green: 0.11, blue: 0.25), // Mid navy #081C40
                    Color(red: 0.01, green: 0.04, blue: 0.12)  // Edge dark blue #020A1F
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 360
            )
            .edgesIgnoringSafeArea(.all)

            // Subtle top aurora bloom
            VStack {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)

            // 2. Centered Content Layout
            VStack(spacing: 20) {
                Spacer()

                // Procedural 3D Windows 7 Aero Flag Orb
                Win7FlagOrb()

                // Authentic Windows 7 Update Copy
                VStack(spacing: 6) {
                    if state.status == .completed {
                        Text("Updates were successfully configured.")
                            .font(Self.segoeFont(size: 20, weight: .light))
                            .foregroundColor(.white)
                        Text("Windows 7 is up to date.")
                            .font(Self.segoeFont(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                    } else if state.status == .cancelled {
                        Text("Installation Cancelled")
                            .font(Self.segoeFont(size: 20, weight: .light))
                            .foregroundColor(.white)
                        Text("The update configuration was cancelled.")
                            .font(Self.segoeFont(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                    } else if state.isRebooting {
                        Text("Restarting Windows...")
                            .font(Self.segoeFont(size: 20, weight: .light))
                            .foregroundColor(.white)
                        Text("Do not turn off your computer.")
                            .font(Self.segoeFont(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                    } else if state.status == .paused {
                        Text("Installation Paused: update \(state.currentUpdateNumber) of \(state.totalUpdateCount)")
                            .font(Self.segoeFont(size: 19, weight: .light))
                            .foregroundColor(.white)
                        Text("Do not turn off your computer.")
                            .font(Self.segoeFont(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                    } else if state.overallProgress > 0.74 {
                        Text("Configuring updates: \(state.percentageInt)% complete.")
                            .font(Self.segoeFont(size: 19, weight: .light))
                            .foregroundColor(.white)
                        Text("Do not turn off your computer.")
                            .font(Self.segoeFont(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                    } else {
                        Text("Installing update \(state.currentUpdateNumber) of \(state.totalUpdateCount)...")
                            .font(Self.segoeFont(size: 19, weight: .light))
                            .foregroundColor(.white)
                        Text("Do not turn off your computer.")
                            .font(Self.segoeFont(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                    }
                }

                // Windows 7 Dedicated Smooth Aero Progress Bar
                VStack(spacing: 8) {
                    Win7ProgressBar(
                        progress: state.overallProgress,
                        accentColor: Color(red: 0.12, green: 0.82, blue: 0.35),
                        isAnimated: state.status == .running
                    )
                    .frame(width: 320)

                    Text(state.status == .completed ? "100% complete" : "\(state.percentageInt)% complete")
                        .font(Self.segoeFont(size: 11))
                        .foregroundColor(Color.cyan.opacity(0.85))
                        .lineLimit(1)
                }

                // Theatrical Easter Egg (strictly opt-in via highVibes personality)
                if let event = state.activeRareEvent, controller.currentSession?.personality != .authentic {
                    HStack(spacing: 6) {
                        Text("✦")
                            .foregroundColor(.cyan)
                        Text(event.primaryMessage)
                            .font(Self.segoeFont(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                }

                Spacer()

                // 3. Footer Actions (Cancel while active, Close when complete)
                HStack {
                    Spacer()

                    if state.status == .completed || state.status == .cancelled {
                        Button("Close") {
                            onClose?()
                        }
                        .buttonStyle(.plain)
                        .font(Self.segoeFont(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 75, height: 23)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                    } else {
                        Button("Cancel") {
                            controller.cancel()
                            onClose?()
                        }
                        .buttonStyle(.plain)
                        .font(Self.segoeFont(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 75, height: 23)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 540, height: 380)
        .fixedSize()
    }
}
