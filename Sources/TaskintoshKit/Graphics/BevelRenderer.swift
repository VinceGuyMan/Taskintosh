import AppKit

public final class BevelRenderer {
    public static let shared = BevelRenderer()

    private init() {}

    /// Draws a classic raised 3D rectangular bevel (used for inactive buttons, dialog borders, Start button).
    public func drawRaisedBevel(in rect: NSRect, theme: EraVisualTheme) {
        guard rect.width > 2 && rect.height > 2 else { return }

        // Outer top and left: lightHighlight
        theme.lightHighlightColor.setFill()
        NSRect(x: rect.minX, y: rect.maxY - 1, width: rect.width, height: 1).fill()
        NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height).fill()

        // Outer bottom and right: darkShadow
        theme.darkShadowColor.setFill()
        NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1).fill()
        NSRect(x: rect.maxX - 1, y: rect.minY, width: 1, height: rect.height).fill()

        // Inner bottom and right: shadow
        theme.shadowColor.setFill()
        NSRect(x: rect.minX + 1, y: rect.minY + 1, width: rect.width - 2, height: 1).fill()
        NSRect(x: rect.maxX - 2, y: rect.minY + 1, width: 1, height: rect.height - 2).fill()
    }

    /// Draws a classic sunken 3D rectangular bevel (used for pressed/active buttons, system tray, text fields).
    public func drawSunkenBevel(in rect: NSRect, theme: EraVisualTheme) {
        guard rect.width > 2 && rect.height > 2 else { return }

        // Outer top and left: darkShadow
        theme.darkShadowColor.setFill()
        NSRect(x: rect.minX, y: rect.maxY - 1, width: rect.width, height: 1).fill()
        NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height).fill()

        // Inner top and left: shadow
        theme.shadowColor.setFill()
        NSRect(x: rect.minX + 1, y: rect.maxY - 2, width: rect.width - 2, height: 1).fill()
        NSRect(x: rect.minX + 1, y: rect.minY + 1, width: 1, height: rect.height - 2).fill()

        // Outer bottom and right: lightHighlight
        theme.lightHighlightColor.setFill()
        NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1).fill()
        NSRect(x: rect.maxX - 1, y: rect.minY, width: 1, height: rect.height).fill()
    }

    /// Draws a thin 1-pixel etched separator or border (groove).
    public func drawEtchedBorder(in rect: NSRect, theme: EraVisualTheme) {
        guard rect.width > 2 && rect.height > 2 else { return }

        // Outer: shadow
        theme.shadowColor.setStroke()
        let path1 = NSBezierPath(rect: NSRect(x: rect.minX + 0.5, y: rect.minY + 0.5, width: rect.width - 2, height: rect.height - 2))
        path1.lineWidth = 1
        path1.stroke()

        // Shifted 1px inner: highlight
        theme.lightHighlightColor.setStroke()
        let path2 = NSBezierPath(rect: NSRect(x: rect.minX + 1.5, y: rect.minY - 0.5, width: rect.width - 2, height: rect.height - 2))
        path2.lineWidth = 1
        path2.stroke()
    }

    /// Draws a 50% alternating checkerboard dither pattern inside a rect, authentic to classic Windows active buttons.
    public func drawActiveDither(in rect: NSRect, theme: EraVisualTheme) {
        theme.surfaceColor.setFill()
        rect.fill()

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()

        let lightColor = theme.lightHighlightColor.cgColor
        context.setFillColor(lightColor)

        let startX = Int(rect.minX)
        let endX = Int(rect.maxX)
        let startY = Int(rect.minY)
        let endY = Int(rect.maxY)

        for y in startY..<endY {
            for x in startX..<endX {
                if (x + y) % 2 == 0 {
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }

        context.restoreGState()
    }
}
