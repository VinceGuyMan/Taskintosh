import SwiftUI

/// Flat, minimalist progress bar characteristic of the Windows 8 / 8.1 Metro design language.
/// Features clean, sharp non-rounded geometry with a flat white progress fill over a translucent white track.
public struct MetroProgressBar: View {
    public let progress: Double
    public var isAnimated: Bool

    public init(progress: Double, isAnimated: Bool = false) {
        if progress.isNaN {
            self.progress = 0.0
        } else if progress.isInfinite {
            self.progress = progress > 0 ? 1.0 : 0.0
        } else {
            self.progress = min(max(progress, 0.0), 1.0)
        }
        self.isAnimated = isAnimated
    }

    public var body: some View {
        GeometryReader { geo in
            let fillWidth = max(0, geo.size.width * CGFloat(progress))

            TimelineView(.animation(paused: !isAnimated)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let totalW = geo.size.width

                ZStack(alignment: .leading) {
                    // Flat track
                    Rectangle()
                        .fill(Color.white.opacity(0.22))

                    // Flat solid white fill
                    if fillWidth > 0 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: fillWidth)
                    }

                    // Authentic Metro traveling caterpillar dots (Windows 8 style)
                    if isAnimated && progress < 1.0 {
                        ForEach(0..<5) { idx in
                            let dotLag = Double(idx) * 0.08
                            let dotCycle = (elapsed * 0.6 - dotLag).truncatingRemainder(dividingBy: 1.8) / 1.8
                            let normalizedT = max(0.0, min(1.0, dotCycle))
                            // Non-linear ease-in-out movement
                            let easedX = (sin((normalizedT - 0.5) * .pi) + 1.0) / 2.0 * (totalW + 20) - 10

                            Rectangle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 4, height: 4)
                                .offset(x: easedX)
                        }
                    }
                }
                .clipShape(Rectangle())
            }
        }
        .frame(height: 4)
    }
}
