import SwiftUI

/// Windows 10 circular dotted spinner animation using TimelineView for continuous motion without macro dependencies.
public struct DottedRingSpinner: View {
    public var dotColor: Color = .white
    public var size: CGFloat = 48

    public init(dotColor: Color = .white, size: CGFloat = 48) {
        self.dotColor = dotColor
        self.size = size
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let angle = (elapsed.truncatingRemainder(dividingBy: 1.4) / 1.4) * 360.0

            ZStack {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(dotColor.opacity(0.3 + Double(index) * 0.14))
                        .frame(width: size * 0.12, height: size * 0.12)
                        .offset(y: -size * 0.42)
                        .rotationEffect(.degrees(Double(index) * 22))
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(angle))
        }
        .frame(width: size, height: size)
    }
}

/// Windows 11 smooth minimalist rotating progress ring using TimelineView.
public struct FluentRingSpinner: View {
    public var strokeColor: Color = Color(red: 0.0, green: 0.47, blue: 0.84) // Windows 11 Blue
    public var size: CGFloat = 44

    public init(strokeColor: Color = Color(red: 0.0, green: 0.47, blue: 0.84), size: CGFloat = 44) {
        self.strokeColor = strokeColor
        self.size = size
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let angle = (elapsed.truncatingRemainder(dividingBy: 1.1) / 1.1) * 360.0

            ZStack {
                // Background Track
                Circle()
                    .stroke(strokeColor.opacity(0.2), lineWidth: 3.5)

                // Animated arc
                Circle()
                    .trim(from: 0.1, to: 0.65)
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}
