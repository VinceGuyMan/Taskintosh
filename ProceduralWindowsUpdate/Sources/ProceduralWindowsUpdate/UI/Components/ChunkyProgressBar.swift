import SwiftUI

/// Segmented chunky progress bar iconic to Windows 95/98/ME setup and update dialogs.
/// Features a recessed sunken trough with tightly packed classic navy blue blocks.
public struct ChunkyProgressBar: View {
    public let progress: Double
    public var blockColor: Color
    public var troughColor: Color
    public var isAnimated: Bool
    public var isMarquee: Bool

    public static let defaultBlockColor = Color(red: 0.0, green: 0.0, blue: 128/255) // Classic Navy #000080
    public static let defaultTroughColor = Color(red: 192/255, green: 192/255, blue: 192/255) // #C0C0C0

    public init(
        progress: Double,
        blockColor: Color = defaultBlockColor,
        troughColor: Color = defaultTroughColor,
        isAnimated: Bool = false,
        isMarquee: Bool = false
    ) {
        if progress.isNaN {
            self.progress = 0.0
        } else {
            self.progress = min(max(progress, 0.0), 1.0)
        }
        self.blockColor = blockColor
        self.troughColor = troughColor
        self.isAnimated = isAnimated
        self.isMarquee = isMarquee
    }

    /// Mathematical calculation for filled vs total blocks matching authentic Windows 95 integer floor scaling:
    /// - progress <= 0: 0 filled blocks
    /// - 0 < progress < 1: floor(progress * total)
    /// - progress >= 1: total filled blocks
    /// - never exceeds total - 1 before 100%
    /// - handles NaN, infinity, and invalid width geometry safely returning (0, 0)
    public static func calculateBlockCount(
        progress: Double,
        totalWidth: CGFloat,
        blockWidth: CGFloat = 6.0,
        spacing: CGFloat = 2.0
    ) -> (filled: Int, total: Int) {
        // Guard against NaN or non-finite inputs
        guard !progress.isNaN else { return (0, 0) }
        guard !totalWidth.isNaN, !totalWidth.isInfinite, totalWidth > 4.0 else { return (0, 0) }
        guard blockWidth > 0, spacing >= 0 else { return (0, 0) }

        let clamped: Double
        if progress.isInfinite {
            clamped = progress > 0 ? 1.0 : 0.0
        } else {
            clamped = min(max(progress, 0.0), 1.0)
        }

        let usableWidth = max(0, totalWidth - 4.0) // 2px left and 2px right bevel inset
        guard usableWidth >= blockWidth else { return (0, 0) }

        let slot = blockWidth + spacing
        let total = max(1, Int((usableWidth + spacing) / slot))

        if clamped <= 0.0 {
            return (0, total)
        } else if clamped >= 1.0 {
            return (total, total)
        } else {
            // Authentic Windows 95 integer floor scaling: floor(progress * total)
            let raw = Int(floor(Double(total) * clamped))
            // Ensure incomplete progress never prematurely renders 100% full (never exceeds total - 1)
            let filled = min(max(raw, 0), total - 1)
            return (filled, total)
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let blockWidth: CGFloat = 6.0
            let blockSpacing: CGFloat = 2.0
            let counts = Self.calculateBlockCount(
                progress: progress,
                totalWidth: geo.size.width,
                blockWidth: blockWidth,
                spacing: blockSpacing
            )

            let usableWidth = max(0, geo.size.width - 4.0)
            let totalSpan = CGFloat(counts.total) * blockWidth + CGFloat(max(0, counts.total - 1)) * blockSpacing
            let sideRemainder = max(0, (usableWidth - totalSpan) / 2.0)
            let leftInset = 2.0 + sideRemainder

            TimelineView(.animation(paused: !isAnimated && !isMarquee)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let marqueeWidth = 4
                let marqueePos = counts.total > marqueeWidth
                    ? Int(elapsed * 12.0).quotientAndRemainder(dividingBy: counts.total + marqueeWidth).remainder - marqueeWidth
                    : 0
                let pulse = (sin(elapsed * 6.0) + 1.0) / 2.0

                ZStack(alignment: .leading) {
                    // Sunken trough background
                    troughColor
                        .classicBevel(.sunken)

                    if isMarquee {
                        // Authentic traveling 3-4 block marquee scan
                        HStack(spacing: blockSpacing) {
                            ForEach(0..<counts.total, id: \.self) { idx in
                                let inMarquee = idx >= marqueePos && idx < (marqueePos + marqueeWidth)
                                Rectangle()
                                    .fill(inMarquee ? blockColor : Color.clear)
                                    .frame(width: blockWidth, height: max(1, geo.size.height - 4.0))
                            }
                        }
                        .padding(.leading, leftInset)
                    } else {
                        // Standard filled navy blocks with subtle animated leading edge pulse
                        HStack(spacing: blockSpacing) {
                            ForEach(0..<counts.filled, id: \.self) { idx in
                                let isLeading = isAnimated && (idx == counts.filled - 1) && counts.filled < counts.total
                                Rectangle()
                                    .fill(
                                        isLeading
                                            ? blockColor.opacity(0.75 + 0.25 * pulse)
                                            : blockColor
                                    )
                                    .frame(width: blockWidth, height: max(1, geo.size.height - 4.0))
                            }
                        }
                        .padding(.leading, leftInset)
                    }
                }
            }
        }
        .frame(height: 16)
    }
}
