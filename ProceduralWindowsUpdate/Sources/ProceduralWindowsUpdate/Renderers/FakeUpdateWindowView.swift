import SwiftUI
import AppKit

/// Unified container view that dynamically switches between era-specific renderers.
/// Displays the simulated update show safely.
public struct FakeUpdateWindowView: View {
    @ObservedObject public var controller: FakeUpdateController
    public var onClose: (() -> Void)?

    public init(
        controller: FakeUpdateController,
        onClose: (() -> Void)? = nil
    ) {
        self.controller = controller
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            // Era-specific renderer dispatch
            switch controller.activeEra.presentationFamily {
            case .classicDialog:
                Win95UpdateRenderer(controller: controller, onClose: onClose)
            case .lunaWizard:
                WinXPUpdateRenderer(controller: controller, onClose: onClose)
            case .aeroGlass:
                WinVistaUpdateRenderer(controller: controller, onClose: onClose)
            case .blueTheater:
                Win7UpdateRenderer(controller: controller, onClose: onClose)
            case .metroFullscreen:
                Win8UpdateRenderer(controller: controller, onClose: onClose)
            case .ringSpinner:
                Win10UpdateRenderer(controller: controller, onClose: onClose)
            case .modernMinimal:
                Win11UpdateRenderer(controller: controller, onClose: onClose)
            }
        }
        .ignoresSafeArea()
    }
}
