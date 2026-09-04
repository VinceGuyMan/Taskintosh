import SwiftUI

/// Authentic Windows 10 circular dotted spinner animation using TimelineView.
/// Features 5 smoothly orbiting circular dots with acceleration/deceleration,
/// support for pausing, and safety against NaN/infinite dimensions.
public struct Win10DottedSpinner: View {
    public var size: CGFloat
    public var dotColor: Color
    public var isPaused: Bool

    public init(
        size: CGFloat = 52,
        dotColor: Color = .white,
        isPaused: Bool = false
    ) {
        if size.isNaN || size.isInfinite || size <= 0 {
            self.size = 52
        } else {
            self.size = size
        }
        self.dotColor = dotColor
        self.isPaused = isPaused
    }

    public var body: some View {
        TimelineView(.animation(paused: isPaused)) { timeline in
            let elapsed = isPaused ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            let period = 2.4

            ZStack {
                ForEach(0..<5) { index in
                    let lag = Double(index) * 0.11
                    let t = isPaused ? 0.0 : max(0.0, (elapsed - lag).truncatingRemainder(dividingBy: period) / period)
                    // Windows 10 signature ease (slow top entry, rapid bottom sweep, slow top exit)
                    let eased = t < 0.5 ? 2.0 * t * t : -1.0 + (4.0 - 2.0 * t) * t
                    let angle = isPaused ? Double(index) * 18.0 : eased * 360.0

                    Circle()
                        .fill(dotColor.opacity(0.40 + Double(index) * 0.15))
                        .frame(width: max(2, size * 0.11), height: max(2, size * 0.11))
                        .offset(y: -size * 0.42)
                        .rotationEffect(.degrees(angle))
                }
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}
