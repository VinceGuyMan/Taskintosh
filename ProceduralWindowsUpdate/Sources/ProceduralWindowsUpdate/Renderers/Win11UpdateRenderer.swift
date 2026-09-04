import SwiftUI
import AppKit

/// Windows 11 refined dark Mica update theater renderer.
/// Characterized by a dark Mica surface with restrained tonal depth,
/// centered Fluent composition, smooth rotating Fluent progress ring,
/// authentic Windows 11 update copy, and period-accurate Fluent button controls.
public struct Win11UpdateRenderer: View {
    @ObservedObject public var controller: FakeUpdateController
    public var onClose: (() -> Void)?

    public init(controller: FakeUpdateController, onClose: (() -> Void)? = nil) {
        self.controller = controller
        self.onClose = onClose
    }

    /// Typography helper: prefers Segoe UI Light if available, falls back to system light font.
    public static func segoeLightFont(size: CGFloat) -> Font {
        #if canImport(AppKit)
        if NSFont(name: "SegoeUI-Light", size: size) != nil || NSFont(name: "Segoe UI Light", size: size) != nil {
            return .custom("SegoeUI-Light", size: size)
        } else if NSFont(name: "Segoe UI", size: size) != nil {
            return .custom("Segoe UI", size: size)
        }
        #endif
        return .system(size: size, weight: .light, design: .default)
    }

    /// Typography helper: prefers Segoe UI Regular if available, falls back to system font.
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
            // Dark Mica/acrylic-inspired surface with subtle tonal depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.13, blue: 0.16), // Dark neutral Mica center #1F2129
                    Color(red: 0.08, green: 0.09, blue: 0.11), // Mid tone #14171C
                    Color(red: 0.05, green: 0.05, blue: 0.07)  // Deep perimeter #0D0D12
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 360
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 22) {
                Spacer()

                // Fluent Rotating Progress Ring (visible during active, paused, or rebooting phases)
                if state.status != .completed && state.status != .cancelled {
                    Win11ProgressRing(
                        size: 48,
                        strokeColor: Color(red: 0.0, green: 0.47, blue: 0.84),
                        isPaused: state.status == .paused
                    )
                }

                // Authentic Windows 11 Copy
                VStack(spacing: 8) {
                    if state.status == .completed {
                        Text("Updates complete")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)

                        Text("Your computer is up to date.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.80))
                    } else if state.status == .cancelled {
                        Text("Installation Cancelled")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)

                        Text("The update process was cancelled.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.80))
                    } else if state.isRebooting {
                        Text("Restarting")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)

                        Text("Please keep your computer on.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.80))

                        Text("Your computer may restart several times.")
                            .font(Self.segoeFont(size: 12, weight: .light))
                            .foregroundColor(Color.white.opacity(0.60))
                    } else if state.status == .paused {
                        Text("Updates are paused")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)

                        Text("\(state.percentageInt)%")
                            .font(Self.segoeLightFont(size: 20))
                            .foregroundColor(Color.white.opacity(0.90))

                        Text("Please keep your computer on.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.80))
                    } else {
                        Text("Updates are underway")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)

                        Text("\(state.percentageInt)%")
                            .font(Self.segoeLightFont(size: 20))
                            .foregroundColor(Color.white.opacity(0.90))

                        Text("Please keep your computer on.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.80))

                        Text("Your computer may restart several times.")
                            .font(Self.segoeFont(size: 12, weight: .light))
                            .foregroundColor(Color.white.opacity(0.60))
                    }
                }

                // Minimalist servicing status line
                if state.status != .completed && state.status != .cancelled {
                    VStack(spacing: 3) {
                        Text(state.currentMessage)
                            .font(Self.segoeFont(size: 11))
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0).opacity(0.85))
                            .lineLimit(1)

                        if let file = state.currentFile {
                            Text(file)
                                .font(Self.segoeFont(size: 10))
                                .foregroundColor(Color.white.opacity(0.40))
                                .lineLimit(1)
                        }
                    }
                }

                // Theatrical Easter Egg (strictly opt-in via highVibes personality)
                if let event = state.activeRareEvent, controller.currentSession?.personality != .authentic {
                    Text(event.primaryMessage)
                        .font(Self.segoeFont(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.90))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }

                Spacer()

                // Fluent Action Buttons (Cancel while active, Close when complete)
                HStack {
                    Spacer()

                    if state.status == .completed || state.status == .cancelled {
                        Button("Close") {
                            onClose?()
                        }
                        .buttonStyle(.plain)
                        .font(Self.segoeFont(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 75, height: 24)
                        .background(Color.white.opacity(0.14))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                    } else {
                        Button("Cancel") {
                            controller.cancel()
                            onClose?()
                        }
                        .buttonStyle(.plain)
                        .font(Self.segoeFont(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 75, height: 24)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 540, height: 380)
        .fixedSize()
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
