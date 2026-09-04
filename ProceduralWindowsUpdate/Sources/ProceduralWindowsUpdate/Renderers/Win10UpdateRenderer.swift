import SwiftUI
import AppKit

/// Windows 10 circular dotted spinner update theater renderer.
/// Features a dark charcoal/navy tonal background, animated dotted circular spinner,
/// large Segoe UI Light typography, authentic restart copy, and safe action buttons.
public struct Win10UpdateRenderer: View {
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
            // Dark charcoal/navy background with subtle radial depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.01, green: 0.06, blue: 0.14), // Center dark navy #030F24
                    Color(red: 0.00, green: 0.02, blue: 0.07)  // Edge charcoal black #000512
                ]),
                center: .center,
                startRadius: 30,
                endRadius: 320
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Spacer()

                // Circular dotted spinner (visible during active, paused, and rebooting phases)
                if state.status != .completed && state.status != .cancelled {
                    Win10DottedSpinner(
                        size: 52,
                        dotColor: .white,
                        isPaused: state.status == .paused
                    )
                }

                // Authentic Windows 10 Messaging
                VStack(spacing: 8) {
                    if state.status == .completed {
                        Text("Updates successfully installed")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)
                        Text("Windows 10 is up to date.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                    } else if state.status == .cancelled {
                        Text("Installation Cancelled")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)
                        Text("The update process was cancelled.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                    } else if state.isRebooting {
                        Text("Restarting")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)
                        Text("Your computer will restart several times.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                        Text("Do not turn off your computer.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.65))
                    } else if state.status == .paused {
                        Text("Updates Paused — \(state.percentageInt)% complete")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)
                        Text("Installation is paused. Don’t turn off your computer.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                    } else {
                        Text("Working on updates — \(state.percentageInt)% complete")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)
                        Text("Don’t turn off your computer.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                        Text("Your computer will restart several times.")
                            .font(Self.segoeFont(size: 13, weight: .light))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                }

                // Sub-status / servicing file line
                if state.status != .completed && state.status != .cancelled {
                    VStack(spacing: 4) {
                        Text(state.currentMessage)
                            .font(Self.segoeFont(size: 12))
                            .foregroundColor(Color.cyan.opacity(0.80))
                            .lineLimit(1)

                        if let file = state.currentFile {
                            Text("Installing: \(file)")
                                .font(Self.segoeFont(size: 11))
                                .foregroundColor(Color.white.opacity(0.50))
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
                        .cornerRadius(4)
                }

                Spacer()

                // Bottom Action Controls (Cancel while active, Close when complete)
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
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
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
                        .frame(width: 75, height: 24)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
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
