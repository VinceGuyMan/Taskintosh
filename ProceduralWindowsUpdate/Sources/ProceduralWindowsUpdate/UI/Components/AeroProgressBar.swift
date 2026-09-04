import SwiftUI

/// Smooth glowing Aero-style progress bar characteristic of Windows Vista and Windows 7.
public struct AeroProgressBar: View {
    public let progress: Double
    public var accentColor: Color = Color(red: 0.1, green: 0.75, blue: 0.3) // Vista/7 green glow
    public var isAnimated: Bool

    public init(
        progress: Double,
        accentColor: Color = Color(red: 0.1, green: 0.75, blue: 0.3),
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
                let beamWidth: CGFloat = 50.0
                let totalTravel = fillWidth + beamWidth * 2
                let beamOffset = totalTravel > 0
                    ? CGFloat((elapsed * 1.3).truncatingRemainder(dividingBy: 2.0) / 2.0) * totalTravel - beamWidth
                    : 0

                ZStack(alignment: .leading) {
                    // Background trough
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
                                            accentColor.opacity(0.8)
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
                                .frame(height: geo.size.height * 0.45)
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
                                                Color.white.opacity(0.8),
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
                        .shadow(color: accentColor.opacity(0.6), radius: 4, x: 0, y: 0)
                    }
                }
            }
        }
        .frame(height: 18)
    }
}
