import AppKit

/// Single-line menu text that stays inside its visual slot on narrow era layouts.
enum StartMenuText {
    static func fitted(_ text: String, font: NSFont, color: NSColor, maxWidth: CGFloat) -> NSAttributedString {
        func attributed(_ value: String, with font: NSFont) -> NSAttributedString {
            NSAttributedString(string: value, attributes: [.font: font, .foregroundColor: color])
        }

        let full = attributed(text, with: font)
        guard maxWidth > 0, full.size().width > maxWidth else { return full }

        // Preserve complete labels where possible by reducing the type a
        // little before resorting to an ellipsis in a narrow tile.
        var pointSize = font.pointSize - 0.5
        while pointSize >= max(8, font.pointSize * 0.82) {
            let compact = attributed(text, with: font.withSize(pointSize))
            if compact.size().width <= maxWidth { return compact }
            pointSize -= 0.5
        }

        var prefix = text
        while !prefix.isEmpty {
            let candidate = attributed(prefix + "…", with: font)
            if candidate.size().width <= maxWidth { return candidate }
            prefix.removeLast()
        }
        return attributed("…", with: font)
    }
}
