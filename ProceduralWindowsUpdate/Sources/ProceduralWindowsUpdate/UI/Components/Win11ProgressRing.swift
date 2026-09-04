import SwiftUI

/// Authentic Windows 11 Fluent rotating progress ring / arc.
/// Features a smooth continuous arc with round line caps rotating over a subtle translucent track,
/// with safe parameter clamping and pause handling.
public struct Win11ProgressRing: View {
    public var size: CGFloat
    public var strokeColor: Color
    public var isPaused: Bool

    public init(
        size: CGFloat = 48,
        strokeColor: Color = Color(red: 0.0, green: 0.47, blue: 0.84),
        isPaused: Bool = false
    ) {
        if size.isNaN || size.isInfinite || size <= 0 {
            self.size = 48
        } else {
            self.size = max(16, min(size, 200))
        }
        self.strokeColor = strokeColor
        self.isPaused = isPaused
    }

    /// Validates and sanitizes dimension inputs against NaN, infinity, and negative bounds.
    public static func sanitize(size: CGFloat) -> CGFloat {
        guard !size.isNaN, !size.isInfinite, size > 0 else { return 48 }
        return max(16, min(size, 200))
    }

    public var body: some View {
        TimelineView(.animation(paused: isPaused)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let angle = isPaused ? 45.0 : (elapsed.truncatingRemainder(dividingBy: 1.4) / 1.4) * 360.0
            let lineWidth = max(2.0, size * 0.07)
            let arcSpan = isPaused ? 0.60 : 0.18 + 0.48 * ((sin(elapsed * 2.8) + 1.0) / 2.0)

            ZStack {
                // Background Track
                Circle()
                    .stroke(
                        strokeColor.opacity(0.18),
                        lineWidth: lineWidth
                    )

                // Smooth Rotating & Breathing Fluent Arc
                Circle()
                    .trim(from: 0.05, to: min(0.95, 0.05 + arcSpan))
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}
