import SwiftUI
import AppKit

/// Windows 8 / 8.1 sparse modern Metro update presentation.
/// Characterized by minimal flat composition, large Segoe UI Light percentage text,
/// a flat 4pt white Metro progress bar, and era-specific authentic palettes and copy.
public struct Win8UpdateRenderer: View {
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
        let era = controller.activeEra
        let is81 = era == .win8_1

        ZStack {
            // Metro Solid Field: Windows 8 Deep Blue/Teal (#004075) vs Windows 8.1 Rich Violet (#2E0A61)
            (is81
                ? Color(red: 0.18, green: 0.04, blue: 0.38)  // Win 8.1 Rich Violet / Eggplant
                : Color(red: 0.0, green: 0.25, blue: 0.46)   // Win 8 Deep Blue / Teal
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                // Large Percentage & Metro Sparse Typography
                VStack(spacing: 8) {
                    if state.status == .completed {
                        Text("100% complete")
                            .font(Self.segoeLightFont(size: 36))
                            .foregroundColor(.white)

                        Text(is81 ? "Windows 8.1 is up to date." : "Windows has finished configuring updates.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                    } else if state.status == .cancelled {
                        Text("Installation Cancelled")
                            .font(Self.segoeLightFont(size: 26))
                            .foregroundColor(.white)

                        Text(is81 ? "The update setup was cancelled." : "The update configuration was cancelled.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                    } else {
                        Text(is81 ? "Setting up updates for Windows 8.1" : "Configuring Windows updates")
                            .font(Self.segoeLightFont(size: 24))
                            .foregroundColor(.white)

                        Text("\(state.percentageInt)% complete")
                            .font(Self.segoeLightFont(size: 36))
                            .foregroundColor(.white)

                        Text("Please do not turn off your computer.")
                            .font(Self.segoeFont(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                }

                // Flat Modern Metro Progress Bar
                VStack(spacing: 8) {
                    MetroProgressBar(progress: state.overallProgress, isAnimated: state.status == .running)
                        .frame(width: 320)

                    if state.status != .completed && state.status != .cancelled {
                        Text("Installing update \(state.currentUpdateNumber) of \(state.totalUpdateCount)")
                            .font(Self.segoeFont(size: 12))
                            .foregroundColor(Color.white.opacity(0.70))
                            .lineLimit(1)
                    }
                }

                // Theatrical Easter Egg (strictly opt-in via highVibes personality)
                if let event = state.activeRareEvent, controller.currentSession?.personality != .authentic {
                    Text(event.primaryMessage)
                        .font(Self.segoeFont(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.25))
                }

                Spacer()

                // Flat Metro Action Button (Cancel while active, Close when complete)
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
                        .background(Color.white.opacity(0.18))
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.40), lineWidth: 1)
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
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.30), lineWidth: 1)
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
