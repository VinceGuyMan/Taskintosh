import SwiftUI

/// Authentic Windows XP Luna-themed green segmented progress bar.
/// Features a crisp 1px blue-gray border (#7F9DB9) enclosing glossy lime/forest green blocks.
public struct LunaProgressBar: View {
    public let progress: Double
    public var blockWidth: CGFloat = 7.0
    public var blockSpacing: CGFloat = 2.0
    public var isAnimated: Bool

    public init(
        progress: Double,
        blockWidth: CGFloat = 7.0,
        blockSpacing: CGFloat = 2.0,
        isAnimated: Bool = false
    ) {
        if progress.isNaN {
            self.progress = 0.0
        } else {
            self.progress = min(max(progress, 0.0), 1.0)
        }
        self.blockWidth = blockWidth
        self.blockSpacing = blockSpacing
        self.isAnimated = isAnimated
    }

    /// Mathematical calculation for filled vs total blocks using integer floor scaling.
    /// - progress <= 0.0: 0 filled blocks
    /// - 0 < progress < 1.0: floor(progress * total), capped at total - 1
    /// - progress >= 1.0: total filled blocks
    public static func calculateBlockCount(
        progress: Double,
        totalWidth: CGFloat,
        blockWidth: CGFloat = 7.0,
        spacing: CGFloat = 2.0
    ) -> (filled: Int, total: Int) {
        guard !progress.isNaN else { return (0, 0) }
        guard !totalWidth.isNaN, !totalWidth.isInfinite, totalWidth > 4.0 else { return (0, 0) }
        guard blockWidth > 0, spacing >= 0 else { return (0, 0) }

        let clamped: Double
        if progress.isInfinite {
            clamped = progress > 0 ? 1.0 : 0.0
        } else {
            clamped = min(max(progress, 0.0), 1.0)
        }

        let usableWidth = max(0, totalWidth - 4.0) // 2px margin inside border
        guard usableWidth >= blockWidth else { return (0, 0) }

        let slot = blockWidth + spacing
        let total = max(1, Int((usableWidth + spacing) / slot))

        if clamped <= 0.0 {
            return (0, total)
        } else if clamped >= 1.0 {
            return (total, total)
        } else {
            let raw = Int(floor(Double(total) * clamped))
            let filled = min(max(raw, 0), total - 1)
            return (filled, total)
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let counts = Self.calculateBlockCount(
                progress: progress,
                totalWidth: geo.size.width,
                blockWidth: blockWidth,
                spacing: blockSpacing
            )

            TimelineView(.animation(paused: !isAnimated)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let sweepPos = counts.filled > 0
                    ? Int(elapsed * 16.0).quotientAndRemainder(dividingBy: counts.filled + 6).remainder - 3
                    : 0

                ZStack(alignment: .leading) {
                    // White trough with 1px Luna border (#7F9DB9)
                    Rectangle()
                        .fill(Color.white)
                        .overlay(
                            Rectangle()
                                .stroke(Color(red: 127/255, green: 157/255, blue: 185/255), lineWidth: 1)
                        )

                    // Segmented green blocks with Luna gloss gradient and active shimmer sweep
                    HStack(spacing: blockSpacing) {
                        ForEach(0..<counts.filled, id: \.self) { idx in
                            let distFromSweep = abs(idx - sweepPos)
                            let sweepGlow = isAnimated && distFromSweep <= 2
                                ? max(0.0, 1.0 - Double(distFromSweep) * 0.4)
                                : 0.0

                            ZStack {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 130/255, green: 228/255, blue: 70/255), // Lime top shine #82E446
                                                Color(red: 56/255, green: 184/255, blue: 24/255),  // Mid green #38B818
                                                Color(red: 30/255, green: 125/255, blue: 12/255)   // Deep base #1E7D0C
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                if sweepGlow > 0 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.45 * sweepGlow))
                                }
                            }
                            .frame(width: blockWidth, height: max(1, geo.size.height - 4))
                            .cornerRadius(1)
                        }
                    }
                    .padding(.leading, 2)
                }
            }
        }
        .frame(height: 16)
    }
}
