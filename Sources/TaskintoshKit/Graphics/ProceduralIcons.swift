import AppKit

public final class ProceduralIcons {
    public static let shared = ProceduralIcons()

    private init() {}

    /// Original 4-quadrant retro 3D emblem.
    public func startEmblem(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let w = rect.width
            let h = rect.height
            let pad: CGFloat = 1.0
            let gap: CGFloat = 2.0
            let halfW = (w - pad * 2 - gap) / 2.0
            let halfH = (h - pad * 2 - gap) / 2.0

            let quadrants: [(NSRect, NSColor, NSColor, NSColor)] = [
                // Top-Left: Red
                (NSRect(x: pad, y: pad + halfH + gap, width: halfW, height: halfH),
                 NSColor(srgbRed: 0.85, green: 0.2, blue: 0.2, alpha: 1.0),
                 NSColor(srgbRed: 1.0, green: 0.6, blue: 0.6, alpha: 1.0),
                 NSColor(srgbRed: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)),
                // Top-Right: Green
                (NSRect(x: pad + halfW + gap, y: pad + halfH + gap, width: halfW, height: halfH),
                 NSColor(srgbRed: 0.2, green: 0.65, blue: 0.25, alpha: 1.0),
                 NSColor(srgbRed: 0.6, green: 0.95, blue: 0.6, alpha: 1.0),
                 NSColor(srgbRed: 0.1, green: 0.4, blue: 0.1, alpha: 1.0)),
                // Bottom-Left: Blue
                (NSRect(x: pad, y: pad, width: halfW, height: halfH),
                 NSColor(srgbRed: 0.1, green: 0.45, blue: 0.85, alpha: 1.0),
                 NSColor(srgbRed: 0.6, green: 0.8, blue: 1.0, alpha: 1.0),
                 NSColor(srgbRed: 0.05, green: 0.2, blue: 0.6, alpha: 1.0)),
                // Bottom-Right: Yellow
                (NSRect(x: pad + halfW + gap, y: pad, width: halfW, height: halfH),
                 NSColor(srgbRed: 0.95, green: 0.75, blue: 0.1, alpha: 1.0),
                 NSColor(srgbRed: 1.0, green: 0.95, blue: 0.6, alpha: 1.0),
                 NSColor(srgbRed: 0.7, green: 0.5, blue: 0.0, alpha: 1.0))
            ]

            for (qRect, baseColor, light, dark) in quadrants {
                baseColor.setFill()
                qRect.fill()

                // Bevel highlight top/left
                light.setFill()
                NSRect(x: qRect.minX, y: qRect.maxY - 1, width: qRect.width, height: 1).fill()
                NSRect(x: qRect.minX, y: qRect.minY, width: 1, height: qRect.height).fill()

                // Bevel shadow bottom/right
                dark.setFill()
                NSRect(x: qRect.minX, y: qRect.minY, width: qRect.width, height: 1).fill()
                NSRect(x: qRect.maxX - 1, y: qRect.minY, width: 1, height: qRect.height).fill()
            }
            return true
        }
    }

    public func programsIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            // Retro folder
            let folderRect = NSRect(x: 2, y: 2, width: rect.width - 4, height: rect.height - 6)
            NSColor(srgbRed: 0.95, green: 0.8, blue: 0.2, alpha: 1.0).setFill()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: folderRect.minX, y: folderRect.minY))
            path.line(to: NSPoint(x: folderRect.minX, y: folderRect.maxY))
            path.line(to: NSPoint(x: folderRect.minX + 6, y: folderRect.maxY))
            path.line(to: NSPoint(x: folderRect.minX + 8, y: folderRect.maxY + 2))
            path.line(to: NSPoint(x: folderRect.maxX, y: folderRect.maxY + 2))
            path.line(to: NSPoint(x: folderRect.maxX, y: folderRect.minY))
            path.close()
            path.fill()
            NSColor.black.setStroke()
            path.lineWidth = 1
            path.stroke()

            // Mini window inside folder
            let winRect = NSRect(x: 5, y: 4, width: 10, height: 7)
            NSColor.white.setFill()
            winRect.fill()
            NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0).setFill()
            NSRect(x: 5, y: 9, width: 10, height: 2).fill()
            return true
        }
    }

    public func documentsIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let docRect = NSRect(x: 4, y: 2, width: rect.width - 8, height: rect.height - 4)
            NSColor.white.setFill()
            docRect.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(docRect)

            NSColor.gray.setFill()
            NSRect(x: 6, y: 12, width: 8, height: 1.5).fill()
            NSRect(x: 6, y: 9, width: 8, height: 1.5).fill()
            NSRect(x: 6, y: 6, width: 6, height: 1.5).fill()
            return true
        }
    }

    public func settingsIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let bg = NSRect(x: 2, y: 3, width: rect.width - 4, height: rect.height - 6)
            NSColor.lightGray.setFill()
            bg.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(bg)

            NSColor.darkGray.setFill()
            NSRect(x: 4, y: 12, width: 12, height: 1.5).fill()
            NSRect(x: 4, y: 6, width: 12, height: 1.5).fill()

            NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0).setFill()
            NSRect(x: 6, y: 10, width: 3, height: 5).fill()
            NSRect(x: 11, y: 4, width: 3, height: 5).fill()
            return true
        }
    }

    public func findIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let circle = NSBezierPath(ovalIn: NSRect(x: 4, y: 6, width: 9, height: 9))
            NSColor(srgbRed: 0.8, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
            circle.fill()
            NSColor.black.setStroke()
            circle.lineWidth = 1.5
            circle.stroke()

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 12, y: 8))
            handle.line(to: NSPoint(x: 17, y: 3))
            NSColor(srgbRed: 0.6, green: 0.1, blue: 0.1, alpha: 1.0).setStroke()
            handle.lineWidth = 2.5
            handle.stroke()
            return true
        }
    }

    public func helpIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let book = NSRect(x: 4, y: 2, width: rect.width - 8, height: rect.height - 4)
            NSColor(srgbRed: 0.4, green: 0.3, blue: 0.7, alpha: 1.0).setFill()
            book.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(book)

            let font = NSFont.boldSystemFont(ofSize: 11)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
            let str = NSAttributedString(string: "?", attributes: attrs)
            str.draw(at: NSPoint(x: 7.5, y: 3.5))
            return true
        }
    }

    public func runIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let win = NSRect(x: 2, y: 3, width: rect.width - 4, height: rect.height - 6)
            NSColor.lightGray.setFill()
            win.fill()
            NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0).setFill()
            NSRect(x: 2, y: rect.height - 7, width: rect.width - 4, height: 4).fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(win)

            // Arrow
            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: 5, y: 6))
            arrow.line(to: NSPoint(x: 9, y: 8.5))
            arrow.line(to: NSPoint(x: 5, y: 11))
            arrow.close()
            NSColor(srgbRed: 0.2, green: 0.6, blue: 0.2, alpha: 1.0).setFill()
            arrow.fill()
            return true
        }
    }

    public func shutDownIcon(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let monitor = NSRect(x: 3, y: 6, width: rect.width - 6, height: rect.height - 9)
            NSColor(srgbRed: 0.9, green: 0.9, blue: 0.88, alpha: 1.0).setFill()
            monitor.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(monitor)

            // Screen
            let screen = NSRect(x: 5, y: 8, width: rect.width - 10, height: rect.height - 13)
            NSColor(srgbRed: 0.8, green: 0.2, blue: 0.2, alpha: 1.0).setFill()
            screen.fill()

            // Stand
            let stand = NSRect(x: 7, y: 2, width: 6, height: 4)
            NSColor.darkGray.setFill()
            stand.fill()
            return true
        }
    }

    public func soundIcon(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 2, y: 5))
            path.line(to: NSPoint(x: 5, y: 5))
            path.line(to: NSPoint(x: 8, y: 2))
            path.line(to: NSPoint(x: 8, y: 14))
            path.line(to: NSPoint(x: 5, y: 11))
            path.line(to: NSPoint(x: 2, y: 11))
            path.close()
            NSColor.black.setFill()
            path.fill()

            // Waves
            let wave = NSBezierPath()
            wave.appendArc(withCenter: NSPoint(x: 7, y: 8), radius: 4, startAngle: -45, endAngle: 45)
            NSColor.black.setStroke()
            wave.lineWidth = 1.2
            wave.stroke()
            return true
        }
    }

    public func taskintoshIcon(size: CGFloat = 24) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            // Retro classic computer shape
            let body = NSRect(x: 3, y: 2, width: rect.width - 6, height: rect.height - 4)
            NSColor(srgbRed: 0.9, green: 0.88, blue: 0.82, alpha: 1.0).setFill()
            body.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(body)

            // Screen
            let screen = NSRect(x: 5, y: 8, width: rect.width - 10, height: rect.height - 12)
            NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0).setFill()
            screen.fill()

            // Floppy drive slot
            let slot = NSRect(x: 6, y: 4, width: 8, height: 1.5)
            NSColor.black.setFill()
            slot.fill()
            return true
        }
    }
}
