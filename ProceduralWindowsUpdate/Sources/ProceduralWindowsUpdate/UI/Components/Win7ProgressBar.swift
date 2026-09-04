import SwiftUI

/// Authentic Windows 7 smooth glowing Aero progress bar.
/// Features a dark blue translucent glass trough with subtle cyan/white border
/// and a glossy vibrant green progress fill with specular top highlight.
public struct Win7ProgressBar: View {
    public let progress: Double
    public var accentColor: Color = Color(red: 0.12, green: 0.82, blue: 0.35)
    public var isAnimated: Bool

    public init(
        progress: Double,
        accentColor: Color = Color(red: 0.12, green: 0.82, blue: 0.35),
        isAnimated: Bool = false
    ) {
        if progress.isNaN {
            self.progress = 0.0
        } else if progress.isInfinite {
            self.progress = progress > 0 ? 1.0 : 0.0
        } else {
            self.progress = min(max(progress, 0.0), 1.0)
        }
        self.accentColor = accentColor
        self.isAnimated = isAnimated
    }

    public var body: some View {
        GeometryReader { geo in
            let fillWidth = max(0, geo.size.width * CGFloat(progress))

            TimelineView(.animation(paused: !isAnimated)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let beamWidth: CGFloat = 60.0
                let totalTravel = fillWidth + beamWidth * 2
                let beamOffset = totalTravel > 0
                    ? CGFloat((elapsed * 1.4).truncatingRemainder(dividingBy: 2.0) / 2.0) * totalTravel - beamWidth
                    : 0

                ZStack(alignment: .leading) {
                    // Background dark blue glass trough with subtle inner shadow
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.02, green: 0.06, blue: 0.16, opacity: 0.65))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.25), Color.cyan.opacity(0.15)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )

                    // Fill with gloss gradient
                    if fillWidth > 0 {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            accentColor.opacity(0.95),
                                            accentColor,
                                            accentColor.opacity(0.80)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Top highlight gloss line
                            VStack {
                                LinearGradient(
                                    colors: [Color.white.opacity(0.65), Color.white.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: max(1, geo.size.height * 0.45))
                                Spacer()
                            }

                            // Moving specular glass shimmer beam
                            if isAnimated {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.clear,
                                                Color.white.opacity(0.55),
                                                Color.white.opacity(0.85),
                                                Color.clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: beamWidth)
                                    .offset(x: beamOffset)
                            }
                        }
                        .frame(width: fillWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .shadow(color: accentColor.opacity(0.55), radius: 4, x: 0, y: 0)
                    }
                }
            }
        }
        .frame(height: 16)
    }
}
