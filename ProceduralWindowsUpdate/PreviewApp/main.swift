import SwiftUI
import AppKit
import ProceduralWindowsUpdate

@MainActor
final class PreviewViewModel: ObservableObject {
    @Published var controller = FakeUpdateController(era: .win95)
    @Published var selectedEra: WindowsEra = .win95
    @Published var selectedDuration: UpdateDuration = .short
    @Published var selectedPersonality: PersonalityIntensity = .authentic
    @Published var seedText: String = "1995"
    @Published var isScreenshotMode: Bool = false

    /// Period-authentic default desktop background color
    var desktopBackground: Color {
        switch selectedEra {
        case .win95, .win98, .winME:
            // Iconic Windows 95/98 Teal #008080
            return Color(red: 0.0, green: 128/255, blue: 128/255)
        case .winXP:
            // Classic Luna Bliss Sky Blue
            return Color(red: 40/255, green: 110/255, blue: 215/255)
        case .winVista, .win7:
            // Deep Windows 7 Slate Blue
            return Color(red: 14/255, green: 44/255, blue: 82/255)
        case .win8, .win8_1:
            return Color(red: 0.0, green: 72/255, blue: 72/255)
        case .win10, .win11:
            return Color(red: 24/255, green: 26/255, blue: 32/255)
        }
    }
}

/// Standalone interactive preview application for testing and admiring ProceduralWindowsUpdate.
@main
struct FakeUpdatePreviewApp: App {
    @StateObject private var model = PreviewViewModel()

    var body: some Scene {
        WindowGroup {
            let controller = model.controller

            ZStack {
                // Neutral Desktop-Like Background (Double-click toggles developer controls)
                model.desktopBackground
                    .edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        model.isScreenshotMode.toggle()
                    }

                // Centered Authentic Dialog Preview
                FakeUpdateWindowView(controller: controller, onClose: {
                    controller.reset()
                })

                // Top Collapsible Developer Controls (Completely removed in Screenshot Mode)
                if !model.isScreenshotMode {
                    VStack {
                        VStack(spacing: 8) {
                            // Top Control Toolbar
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ERA")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $model.selectedEra) {
                                        ForEach(WindowsEra.allCases) { era in
                                            Text(era.rawValue).tag(era)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 140)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("MODE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $model.selectedPersonality) {
                                        Text("Authentic (Default)").tag(PersonalityIntensity.authentic)
                                        Text("Theatrical (Easter Eggs)").tag(PersonalityIntensity.highVibes)
                                    }
                                    .labelsHidden()
                                    .frame(width: 160)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("DURATION")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $model.selectedDuration) {
                                        Text("Short (~12s)").tag(UpdateDuration.short)
                                        Text("Normal (~28s)").tag(UpdateDuration.normal)
                                        Text("Theatrical (~65s)").tag(UpdateDuration.theatrical)
                                    }
                                    .labelsHidden()
                                    .frame(width: 130)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SEED")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        TextField("Seed", text: $model.seedText)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 65)

                                        Button("🎲") {
                                            model.seedText = String(UInt64.random(in: 100...999999))
                                        }
                                        .help("Random Seed")
                                    }
                                }

                                Spacer()

                                // Action Buttons
                                HStack(spacing: 6) {
                                    if controller.state.status.isActive {
                                        Button("Cancel") {
                                            controller.cancel()
                                        }
                                        .foregroundColor(.red)
                                    } else {
                                        Button("Start Setup") {
                                            let seed = UInt64(model.seedText) ?? 1995
                                            controller.start(
                                                era: model.selectedEra,
                                                duration: model.selectedDuration,
                                                personality: model.selectedPersonality,
                                                seed: seed
                                            )
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }

                                    Button("Reset") {
                                        controller.reset()
                                    }
                                }
                            }

                            // Quick Presets & Screenshot Mode Toggle
                            HStack(spacing: 8) {
                                Text("Presets:")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Button("Win95") {
                                    model.selectedEra = .win95
                                    model.selectedPersonality = .authentic
                                    model.seedText = "1995"
                                    controller.start(era: .win95, duration: .short, personality: .authentic, seed: 1995)
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 11))

                                Text("•").foregroundColor(.secondary)

                                Button("Win98") {
                                    model.selectedEra = .win98
                                    model.selectedPersonality = .authentic
                                    model.seedText = "1998"
                                    controller.start(era: .win98, duration: .short, personality: .authentic, seed: 1998)
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 11))

                                Text("•").foregroundColor(.secondary)

                                Button("WinME") {
                                    model.selectedEra = .winME
                                    model.selectedPersonality = .authentic
                                    model.seedText = "2000"
                                    controller.start(era: .winME, duration: .short, personality: .authentic, seed: 2000)
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 11))

                                Text("•").foregroundColor(.secondary)

                                Button("Theatrical (Seed 42)") {
                                    model.selectedEra = .winXP
                                    model.selectedPersonality = .highVibes
                                    model.seedText = "42"
                                    controller.start(era: .winXP, duration: .short, personality: .highVibes, seed: 42)
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 11))

                                Spacer()

                                Button("📷 Screenshot Mode") {
                                    model.isScreenshotMode = true
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .help("Hides all controls. Double-click desktop to restore.")
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                        .padding(10)

                        Spacer()
                    }
                }
            }
            .frame(minWidth: 700, minHeight: 480)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
