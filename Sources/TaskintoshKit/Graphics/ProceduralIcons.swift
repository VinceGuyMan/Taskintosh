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

    public func soundIcon(size: CGFloat = 16, color: NSColor = .black, isMuted: Bool = false) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 16.0
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 2 * scale, y: 5 * scale))
            path.line(to: NSPoint(x: 5 * scale, y: 5 * scale))
            path.line(to: NSPoint(x: 8 * scale, y: 2 * scale))
            path.line(to: NSPoint(x: 8 * scale, y: 14 * scale))
            path.line(to: NSPoint(x: 5 * scale, y: 11 * scale))
            path.line(to: NSPoint(x: 2 * scale, y: 11 * scale))
            path.close()
            color.setFill()
            path.fill()

            if isMuted {
                // Red X
                let xPath = NSBezierPath()
                xPath.move(to: NSPoint(x: 10 * scale, y: 5 * scale))
                xPath.line(to: NSPoint(x: 14 * scale, y: 11 * scale))
                xPath.move(to: NSPoint(x: 14 * scale, y: 5 * scale))
                xPath.line(to: NSPoint(x: 10 * scale, y: 11 * scale))
                NSColor(srgbRed: 0.85, green: 0.15, blue: 0.15, alpha: 1.0).setStroke()
                xPath.lineWidth = 1.4 * scale
                xPath.stroke()
            } else {
                // Waves
                let wave1 = NSBezierPath()
                wave1.appendArc(withCenter: NSPoint(x: 7 * scale, y: 8 * scale), radius: 3.5 * scale, startAngle: -45, endAngle: 45)
                color.setStroke()
                wave1.lineWidth = 1.2 * scale
                wave1.stroke()

                let wave2 = NSBezierPath()
                wave2.appendArc(withCenter: NSPoint(x: 7 * scale, y: 8 * scale), radius: 6.0 * scale, startAngle: -45, endAngle: 45)
                color.setStroke()
                wave2.lineWidth = 1.2 * scale
                wave2.stroke()
            }
            return true
        }
    }

    public func taskintoshIcon(size: CGFloat = 24) -> NSImage {
        // First check Bundle.module for official brand asset
        #if SWIFT_PACKAGE
        if let iconURL = Bundle.module.url(forResource: "taskintosh-icon", withExtension: "png", subdirectory: "Brand"),
           let img = NSImage(contentsOf: iconURL) {
            let resized = NSImage(size: NSSize(width: size, height: size))
            resized.lockFocus()
            img.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1.0)
            resized.unlockFocus()
            return resized
        }
        #endif

        // Check main bundle resources
        if let mainURL = Bundle.main.url(forResource: "taskintosh-icon-32", withExtension: "png"),
           let img = NSImage(contentsOf: mainURL) {
            let resized = NSImage(size: NSSize(width: size, height: size))
            resized.lockFocus()
            img.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1.0)
            resized.unlockFocus()
            return resized
        }

        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            // Retro classic computer shape fallback
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

    /// Pure white / monochrome template icon specifically for the macOS menu bar.
    /// Uses isTemplate = true so macOS automatically styles it in pure crisp white on dark menubars/wallpapers,
    /// or dark on light menubars, perfectly matching system icons (Wi-Fi, Control Center, battery).
    public func taskintoshTemplateIcon(size: CGFloat = 16) -> NSImage {
        let templateImg = NSImage(size: NSSize(width: size, height: size))

        var url1x: URL? = nil
        var url2x: URL? = nil

        #if SWIFT_PACKAGE
        url1x = Bundle.module.url(forResource: "taskintosh-mono-white", withExtension: "png", subdirectory: "Brand")
        url2x = Bundle.module.url(forResource: "taskintosh-mono-white@2x", withExtension: "png", subdirectory: "Brand")
        #endif

        if url1x == nil {
            url1x = Bundle.main.url(forResource: "taskintosh-menu-icon", withExtension: "png")
                ?? Bundle.main.url(forResource: "taskintosh-mono-white", withExtension: "png", subdirectory: "Brand")
                ?? Bundle.main.url(forResource: "taskintosh-mono-white", withExtension: "png")
        }
        if url2x == nil {
            url2x = Bundle.main.url(forResource: "taskintosh-menu-icon@2x", withExtension: "png")
                ?? Bundle.main.url(forResource: "taskintosh-mono-white@2x", withExtension: "png", subdirectory: "Brand")
                ?? Bundle.main.url(forResource: "taskintosh-mono-white@2x", withExtension: "png")
        }

        var loadedRep = false
        if let u1x = url1x, let data1x = try? Data(contentsOf: u1x),
           let rep1x = NSBitmapImageRep(data: data1x) {
            rep1x.size = NSSize(width: size, height: size)
            templateImg.addRepresentation(rep1x)
            loadedRep = true
        }

        if let u2x = url2x, let data2x = try? Data(contentsOf: u2x),
           let rep2x = NSBitmapImageRep(data: data2x) {
            rep2x.size = NSSize(width: size, height: size)
            templateImg.addRepresentation(rep2x)
            loadedRep = true
        }

        if loadedRep {
            templateImg.isTemplate = true
            return templateImg
        }

        // Fallback: draw crisp vector template icon
        let template = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSColor.white.setFill()
            let body = NSRect(x: 2, y: 2, width: rect.width - 4, height: rect.height - 4)
            NSBezierPath(roundedRect: body, xRadius: 2, yRadius: 2).fill()
            return true
        }
        template.isTemplate = true
        return template
    }

    /// Windows XP style curved emblem.
    public func lunaStartEmblem(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let w = rect.width
            let h = rect.height
            let pad: CGFloat = 1.0
            let qW = (w - pad * 2) * 0.45
            let qH = (h - pad * 2) * 0.45

            let colors: [(NSRect, NSColor)] = [
                (NSRect(x: pad, y: pad + qH + 1, width: qW, height: qH), NSColor(srgbRed: 0.95, green: 0.25, blue: 0.15, alpha: 1.0)),
                (NSRect(x: pad + qW + 1, y: pad + qH + 1, width: qW, height: qH), NSColor(srgbRed: 0.3, green: 0.75, blue: 0.2, alpha: 1.0)),
                (NSRect(x: pad, y: pad, width: qW, height: qH), NSColor(srgbRed: 0.1, green: 0.5, blue: 0.95, alpha: 1.0)),
                (NSRect(x: pad + qW + 1, y: pad, width: qW, height: qH), NSColor(srgbRed: 0.95, green: 0.75, blue: 0.1, alpha: 1.0))
            ]

            for (r, col) in colors {
                col.setFill()
                let path = NSBezierPath(roundedRect: r, xRadius: 1.5, yRadius: 1.5)
                path.fill()
            }
            return true
        }
    }

    /// Vista / Win 7 3D circular Aero glass orb.
    public func aeroStartOrb(size: CGFloat = 32) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let circleRect = rect.insetBy(dx: 1, dy: 1)

            // Outer dark sphere
            let outerPath = NSBezierPath(ovalIn: circleRect)
            NSColor(srgbRed: 0.05, green: 0.15, blue: 0.3, alpha: 0.95).setFill()
            outerPath.fill()

            // Outer cyan glow ring
            NSColor(srgbRed: 0.3, green: 0.7, blue: 0.95, alpha: 0.8).setStroke()
            outerPath.lineWidth = 1.5
            outerPath.stroke()

            // Inner mini emblem
            let emblem = self.lunaStartEmblem(size: circleRect.width * 0.55)
            let emblemRect = NSRect(
                x: circleRect.midX - emblem.size.width / 2.0,
                y: circleRect.midY - emblem.size.height / 2.0,
                width: emblem.size.width,
                height: emblem.size.height
            )
            emblem.draw(in: emblemRect)

            // Top specular gloss
            let glossRect = NSRect(x: circleRect.minX + 3, y: circleRect.midY, width: circleRect.width - 6, height: circleRect.height / 2.0 - 2)
            let glossPath = NSBezierPath(ovalIn: glossRect)
            NSColor(white: 1.0, alpha: 0.35).setFill()
            glossPath.fill()

            return true
        }
    }

    /// Windows 8/10 flat modern 4-tile emblem.
    public func flatStartTiles(size: CGFloat = 16, color: NSColor = .white) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let pad: CGFloat = 1.0
            let gap: CGFloat = 1.5
            let halfW = (rect.width - pad * 2 - gap) / 2.0
            let halfH = (rect.height - pad * 2 - gap) / 2.0

            color.setFill()
            NSRect(x: pad, y: pad + halfH + gap, width: halfW, height: halfH).fill()
            NSRect(x: pad + halfW + gap, y: pad + halfH + gap, width: halfW, height: halfH).fill()
            NSRect(x: pad, y: pad, width: halfW, height: halfH).fill()
            NSRect(x: pad + halfW + gap, y: pad, width: halfW, height: halfH).fill()
            return true
        }
    }

    /// Windows 11 centered modern blue emblem.
    public func win11StartEmblem(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let pad: CGFloat = 2.0
            let gap: CGFloat = 2.0
            let halfW = (rect.width - pad * 2 - gap) / 2.0
            let halfH = (rect.height - pad * 2 - gap) / 2.0

            let blueColor = NSColor(srgbRed: 0.0, green: 0.47, blue: 0.83, alpha: 1.0)
            blueColor.setFill()

            let r1 = NSRect(x: pad, y: pad + halfH + gap, width: halfW, height: halfH)
            let r2 = NSRect(x: pad + halfW + gap, y: pad + halfH + gap, width: halfW, height: halfH)
            let r3 = NSRect(x: pad, y: pad, width: halfW, height: halfH)
            let r4 = NSRect(x: pad + halfW + gap, y: pad, width: halfW, height: halfH)

            NSBezierPath(roundedRect: r1, xRadius: 1.0, yRadius: 1.0).fill()
            NSBezierPath(roundedRect: r2, xRadius: 1.0, yRadius: 1.0).fill()
            NSBezierPath(roundedRect: r3, xRadius: 1.0, yRadius: 1.0).fill()
            NSBezierPath(roundedRect: r4, xRadius: 1.0, yRadius: 1.0).fill()
            return true
        }
    }

    /// Classic Macintosh System 7 / OS 8 retro apple emblem.
    public func appleRetroLogo(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let body = NSRect(x: 2, y: 1, width: rect.width - 4, height: rect.height - 3)
            let path = NSBezierPath(ovalIn: body)
            NSColor(srgbRed: 0.2, green: 0.6, blue: 0.2, alpha: 1.0).setFill()
            path.fill()
            NSColor.black.setStroke()
            path.lineWidth = 1
            path.stroke()

            // Stem
            let stem = NSBezierPath()
            stem.move(to: NSPoint(x: rect.midX, y: rect.maxY - 2))
            stem.line(to: NSPoint(x: rect.midX + 2, y: rect.maxY))
            NSColor.black.setStroke()
            stem.lineWidth = 1.2
            stem.stroke()
            return true
        }
    }

    /// NeXT black 3D cube emblem.
    public func nextCubeLogo(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let box = rect.insetBy(dx: 2, dy: 2)
            NSColor.black.setFill()
            box.fill()

            // 3D edge
            NSColor(srgbRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0).setFill()
            NSRect(x: box.minX, y: box.maxY - 2, width: box.width, height: 2).fill()
            NSRect(x: box.minX, y: box.minY, width: 2, height: box.height).fill()

            // 'N' text
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 11),
                .foregroundColor: NSColor(srgbRed: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
            ]
            let str = NSAttributedString(string: "N", attributes: attrs)
            str.draw(at: NSPoint(x: box.midX - 5, y: box.midY - 7))
            return true
        }
    }

    /// BeOS blue 'B' logo with red highlight.
    public func beLogo(size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let box = rect.insetBy(dx: 1, dy: 1)
            NSColor(srgbRed: 0.1, green: 0.3, blue: 0.75, alpha: 1.0).setFill()
            let path = NSBezierPath(roundedRect: box, xRadius: 3, yRadius: 3)
            path.fill()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: "B", attributes: attrs)
            str.draw(at: NSPoint(x: box.midX - 5, y: box.midY - 8))
            return true
        }
    }

    /// Amiga screen depth gadget.
    public func amigaGadget(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let r1 = NSRect(x: 1, y: 1, width: rect.width - 5, height: rect.height - 5)
            let r2 = NSRect(x: 4, y: 4, width: rect.width - 5, height: rect.height - 5)

            NSColor(srgbRed: 0.0, green: 0.33, blue: 0.66, alpha: 1.0).setFill()
            r1.fill()
            NSColor(srgbRed: 1.0, green: 0.53, blue: 0.0, alpha: 1.0).setStroke()
            NSBezierPath.stroke(r1)

            NSColor.white.setFill()
            r2.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(r2)
            return true
        }
    }

    /// Quick Launch Show Desktop icon.
    public func showDesktopIcon(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let desk = NSRect(x: 1, y: 1, width: rect.width - 2, height: rect.height - 2)
            NSColor(srgbRed: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).setFill()
            desk.fill()
            NSColor.black.setStroke()
            NSBezierPath.stroke(desk)

            // Pen / blotter
            NSColor(srgbRed: 0.1, green: 0.3, blue: 0.7, alpha: 1.0).setFill()
            NSRect(x: 3, y: 3, width: rect.width - 6, height: 6).fill()
            return true
        }
    }

    /// Quick Launch Internet Browser icon.
    public func internetIcon(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let circle = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            NSColor(srgbRed: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).setFill()
            circle.fill()
            NSColor.black.setStroke()
            circle.lineWidth = 1
            circle.stroke()

            // Lat / Long line
            let line = NSBezierPath()
            line.move(to: NSPoint(x: rect.minX + 2, y: rect.midY))
            line.line(to: NSPoint(x: rect.maxX - 2, y: rect.midY))
            NSColor.white.setStroke()
            line.stroke()
            return true
        }
    }

    /// Quick Launch Terminal / Command Prompt icon.
    public func terminalIcon(size: CGFloat = 16) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let box = rect.insetBy(dx: 1, dy: 1)
            NSColor.black.setFill()
            box.fill()
            NSColor.gray.setStroke()
            NSBezierPath.stroke(box)

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 9),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: ">_", attributes: attrs)
            str.draw(at: NSPoint(x: 3, y: 2))
            return true
        }
    }

    /// Windows 10 Action Center speech-bubble icon
    public func actionCenterIcon(size: CGFloat = 14) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let bubble = NSBezierPath()
            let bRect = rect.insetBy(dx: 1.5, dy: 2)
            bubble.move(to: NSPoint(x: bRect.minX, y: bRect.minY + 3))
            bubble.line(to: NSPoint(x: bRect.minX, y: bRect.maxY))
            bubble.line(to: NSPoint(x: bRect.maxX, y: bRect.maxY))
            bubble.line(to: NSPoint(x: bRect.maxX, y: bRect.minY + 3))
            bubble.line(to: NSPoint(x: bRect.minX + 6, y: bRect.minY + 3))
            bubble.line(to: NSPoint(x: bRect.minX + 3, y: bRect.minY))
            bubble.line(to: NSPoint(x: bRect.minX + 3, y: bRect.minY + 3))
            bubble.close()
            NSColor.white.setStroke()
            bubble.lineWidth = 1.0
            bubble.stroke()
            return true
        }
    }

    /// Windows 7 Action Center white security flag
    public func actionCenterFlagIcon(size: CGFloat = 14, color: NSColor = .white) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 14.0
            // Pole
            let pole = NSBezierPath()
            pole.move(to: NSPoint(x: 3 * scale, y: 1 * scale))
            pole.line(to: NSPoint(x: 3 * scale, y: 13 * scale))
            color.setStroke()
            pole.lineWidth = 1.2 * scale
            pole.stroke()

            // Flag
            let flag = NSBezierPath()
            flag.move(to: NSPoint(x: 3.5 * scale, y: 12.5 * scale))
            flag.curve(to: NSPoint(x: 11 * scale, y: 10 * scale), controlPoint1: NSPoint(x: 6 * scale, y: 13.5 * scale), controlPoint2: NSPoint(x: 8.5 * scale, y: 11 * scale))
            flag.line(to: NSPoint(x: 11 * scale, y: 5.5 * scale))
            flag.curve(to: NSPoint(x: 3.5 * scale, y: 8 * scale), controlPoint1: NSPoint(x: 8.5 * scale, y: 6.5 * scale), controlPoint2: NSPoint(x: 6 * scale, y: 9 * scale))
            flag.close()
            color.setFill()
            flag.fill()
            return true
        }
    }

    /// Network connectivity icon (Wi-Fi waves, Ethernet monitor, or WinXP dual CRTs)
    public func networkIcon(size: CGFloat = 14, color: NSColor = .controlTextColor, isConnected: Bool = true, isWiFi: Bool = true, isWinXP: Bool = false) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 14.0
            if isWinXP {
                // Windows XP dual overlapping CRT monitors
                // Back monitor
                let backRect = NSRect(x: 4 * scale, y: 4 * scale, width: 8 * scale, height: 7 * scale)
                NSColor(srgbRed: 0.2, green: 0.4, blue: 0.7, alpha: 1.0).setFill()
                backRect.fill()
                let backScreen = backRect.insetBy(dx: 1 * scale, dy: 1 * scale)
                (isConnected ? NSColor(srgbRed: 0.2, green: 0.9, blue: 0.4, alpha: 1.0) : NSColor.darkGray).setFill()
                backScreen.fill()

                // Front monitor
                let frontRect = NSRect(x: 1 * scale, y: 1 * scale, width: 8 * scale, height: 7 * scale)
                NSColor(srgbRed: 0.15, green: 0.35, blue: 0.65, alpha: 1.0).setFill()
                frontRect.fill()
                let frontScreen = frontRect.insetBy(dx: 1 * scale, dy: 1 * scale)
                (isConnected ? NSColor(srgbRed: 0.3, green: 1.0, blue: 0.5, alpha: 1.0) : NSColor.gray).setFill()
                frontScreen.fill()
            } else if isWiFi {
                // Wi-Fi signal arcs
                let center = NSPoint(x: 7 * scale, y: 2 * scale)
                let dot = NSBezierPath(ovalIn: NSRect(x: 6 * scale, y: 1.5 * scale, width: 2 * scale, height: 2 * scale))
                (isConnected ? color : NSColor.gray).setFill()
                dot.fill()

                for r in [4.5 * scale, 7.5 * scale, 10.5 * scale] {
                    let arc = NSBezierPath()
                    arc.appendArc(withCenter: center, radius: r, startAngle: 45, endAngle: 135)
                    (isConnected ? color : NSColor.gray).setStroke()
                    arc.lineWidth = 1.3 * scale
                    arc.stroke()
                }
            } else {
                // Ethernet monitor with cable
                let monRect = NSRect(x: 2 * scale, y: 4 * scale, width: 10 * scale, height: 8 * scale)
                color.setStroke()
                NSBezierPath(rect: monRect).stroke()
                let stand = NSBezierPath()
                stand.move(to: NSPoint(x: 7 * scale, y: 4 * scale))
                stand.line(to: NSPoint(x: 7 * scale, y: 1.5 * scale))
                stand.move(to: NSPoint(x: 4 * scale, y: 1.5 * scale))
                stand.line(to: NSPoint(x: 10 * scale, y: 1.5 * scale))
                stand.lineWidth = 1.2 * scale
                stand.stroke()
            }
            return true
        }
    }

    /// Battery status icon
    public func batteryIcon(size: CGFloat = 14, color: NSColor = .controlTextColor, percentage: Int = 100, isCharging: Bool = false) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 14.0
            let bodyRect = NSRect(x: 1 * scale, y: 3.5 * scale, width: 10 * scale, height: 7 * scale)
            color.setStroke()
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 1 * scale, yRadius: 1 * scale)
            bodyPath.lineWidth = 1.0 * scale
            bodyPath.stroke()

            // Tip
            let tipRect = NSRect(x: 11 * scale, y: 5.5 * scale, width: 1.5 * scale, height: 3 * scale)
            color.setFill()
            tipRect.fill()

            // Fill
            let fillW = max(0, min(8 * scale, 8 * scale * CGFloat(percentage) / 100.0))
            if fillW > 0 {
                let fillRect = NSRect(x: 2 * scale, y: 4.5 * scale, width: fillW, height: 5 * scale)
                let fillColor = percentage <= 20 ? NSColor.systemRed : color
                fillColor.setFill()
                fillRect.fill()
            }

            if isCharging {
                // Lightning bolt
                let bolt = NSBezierPath()
                bolt.move(to: NSPoint(x: 6.5 * scale, y: 9.5 * scale))
                bolt.line(to: NSPoint(x: 4.5 * scale, y: 6.5 * scale))
                bolt.line(to: NSPoint(x: 6.5 * scale, y: 6.5 * scale))
                bolt.line(to: NSPoint(x: 5.5 * scale, y: 4.0 * scale))
                bolt.line(to: NSPoint(x: 8.0 * scale, y: 7.0 * scale))
                bolt.line(to: NSPoint(x: 6.5 * scale, y: 7.0 * scale))
                bolt.close()
                NSColor.systemYellow.setFill()
                bolt.fill()
            }
            return true
        }
    }

    /// Tray overflow chevron icon
    public func trayChevronIcon(size: CGFloat = 12, color: NSColor = .controlTextColor, isUp: Bool = true) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 12.0
            let path = NSBezierPath()
            if isUp {
                path.move(to: NSPoint(x: 2.5 * scale, y: 4.5 * scale))
                path.line(to: NSPoint(x: 6.0 * scale, y: 8.5 * scale))
                path.line(to: NSPoint(x: 9.5 * scale, y: 4.5 * scale))
            } else {
                path.move(to: NSPoint(x: 8.0 * scale, y: 2.5 * scale))
                path.line(to: NSPoint(x: 4.0 * scale, y: 6.0 * scale))
                path.line(to: NSPoint(x: 8.0 * scale, y: 9.5 * scale))
            }
            color.setStroke()
            path.lineWidth = 1.3 * scale
            path.stroke()
            return true
        }
    }
}

// MARK: - Era-Appropriate System Icons System

public enum SystemIconType: String, CaseIterable {
    case programs
    case documents
    case recentDocuments
    case pictures
    case music
    case myComputer
    case controlPanel
    case settings
    case search
    case help
    case run
    case shutDown
    case logOff
    case restart
    case terminal
    case internet
    case email
    case accessibility
    case eraManager
    case forceQuit
    case goToPath
    case favorites
    case folder
    case openFolder
    case file
    case lock
    case user
    case network
}

extension ProceduralIcons {
    public func icon(for type: SystemIconType, era: EraPackage, size: CGFloat = 20) -> NSImage {
        return icon(for: type, eraType: era.theme.startMenuType, size: size)
    }

    public func icon(for type: SystemIconType, eraType: StartMenuType, size: CGFloat = 20) -> NSImage {
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            switch eraType {
            case .classicOneColumn:
                self.drawWin95Icon(type: type, in: rect)
            case .twoColumnXP:
                self.self.drawWinXPIcon(type: type, in: rect)
            case .twoColumnGlass:
                self.drawWin7Icon(type: type, in: rect)
            case .tileLauncher, .modernTiles:
                self.self.drawWin8Icon(type: type, in: rect)
            case .hybridMenu:
                self.drawWin10Icon(type: type, in: rect)
            case .centeredFlyout:
                self.drawWin11Icon(type: type, in: rect)
            default:
                self.drawWin95Icon(type: type, in: rect)
            }
            return true
        }
    }

    // MARK: - Windows 95 Pixel-Style (16-Color, 1px outlines, chunky forms)
    private func drawWin95Icon(type: SystemIconType, in rect: NSRect) {
        let s = rect.width / 20.0
        let black = NSColor.black
        let white = NSColor.white
        let gray = NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)
        let darkGray = NSColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        let yellow = NSColor(srgbRed: 1.0, green: 0.82, blue: 0.0, alpha: 1.0)
        let blue = NSColor(srgbRed: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)
        let lightBlue = NSColor(srgbRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        let red = NSColor(srgbRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        let green = NSColor(srgbRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)

        switch type {
        case .programs, .folder, .openFolder:
            // Classic 95 Folder
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 2 * s, y: 3 * s))
            path.line(to: NSPoint(x: 2 * s, y: 15 * s))
            path.line(to: NSPoint(x: 8 * s, y: 15 * s))
            path.line(to: NSPoint(x: 10 * s, y: 13 * s))
            path.line(to: NSPoint(x: 18 * s, y: 13 * s))
            path.line(to: NSPoint(x: 18 * s, y: 3 * s))
            path.close()
            yellow.setFill()
            path.fill()
            black.setStroke()
            path.lineWidth = 1 * s
            path.stroke()

            // Folder front flap
            let flap = NSBezierPath()
            flap.move(to: NSPoint(x: 1 * s, y: 3 * s))
            flap.line(to: NSPoint(x: 4 * s, y: 11 * s))
            flap.line(to: NSPoint(x: 19 * s, y: 11 * s))
            flap.line(to: NSPoint(x: 17 * s, y: 3 * s))
            flap.close()
            NSColor(srgbRed: 1.0, green: 0.9, blue: 0.2, alpha: 1.0).setFill()
            flap.fill()
            black.setStroke()
            flap.lineWidth = 1 * s
            flap.stroke()

        case .documents, .recentDocuments, .file:
            // Manila folder with white dog-eared document
            yellow.setFill()
            NSRect(x: 2 * s, y: 3 * s, width: 14 * s, height: 11 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 2 * s, y: 3 * s, width: 14 * s, height: 11 * s)).stroke()

            // White dog-eared document peeking out
            let doc = NSBezierPath()
            doc.move(to: NSPoint(x: 6 * s, y: 6 * s))
            doc.line(to: NSPoint(x: 6 * s, y: 17 * s))
            doc.line(to: NSPoint(x: 13 * s, y: 17 * s))
            doc.line(to: NSPoint(x: 16 * s, y: 14 * s))
            doc.line(to: NSPoint(x: 16 * s, y: 6 * s))
            doc.close()
            white.setFill()
            doc.fill()
            black.setStroke()
            doc.lineWidth = 1 * s
            doc.stroke()

            // Text lines
            black.setFill()
            NSRect(x: 8 * s, y: 13 * s, width: 5 * s, height: 1 * s).fill()
            NSRect(x: 8 * s, y: 10 * s, width: 6 * s, height: 1 * s).fill()
            NSRect(x: 8 * s, y: 7 * s, width: 5 * s, height: 1 * s).fill()

        case .controlPanel, .settings:
            // Classic Control Panel: gray card with sliders
            gray.setFill()
            NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 14 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 14 * s)).stroke()
            // Sliders
            black.setFill()
            NSRect(x: 4 * s, y: 12 * s, width: 12 * s, height: 1 * s).fill()
            NSRect(x: 4 * s, y: 8 * s, width: 12 * s, height: 1 * s).fill()
            NSRect(x: 4 * s, y: 4 * s, width: 12 * s, height: 1 * s).fill()
            // Knobs
            blue.setFill()
            NSRect(x: 6 * s, y: 11 * s, width: 3 * s, height: 3 * s).fill()
            red.setFill()
            NSRect(x: 11 * s, y: 7 * s, width: 3 * s, height: 3 * s).fill()
            green.setFill()
            NSRect(x: 8 * s, y: 3 * s, width: 3 * s, height: 3 * s).fill()

        case .search, .goToPath:
            // Classic Magnifying glass over paper
            white.setFill()
            NSRect(x: 3 * s, y: 4 * s, width: 10 * s, height: 12 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 3 * s, y: 4 * s, width: 10 * s, height: 12 * s)).stroke()

            // Magnifying glass
            let lens = NSBezierPath(ovalIn: NSRect(x: 7 * s, y: 7 * s, width: 8 * s, height: 8 * s))
            NSColor(srgbRed: 0.6, green: 0.9, blue: 1.0, alpha: 0.9).setFill()
            lens.fill()
            black.setStroke()
            lens.lineWidth = 1 * s
            lens.stroke()

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 13.5 * s, y: 8.5 * s))
            handle.line(to: NSPoint(x: 17.5 * s, y: 4.5 * s))
            black.setStroke()
            handle.lineWidth = 2 * s
            handle.stroke()

        case .help:
            // Classic purple Help book with yellow "?"
            NSColor(srgbRed: 0.45, green: 0.1, blue: 0.55, alpha: 1.0).setFill()
            NSRect(x: 3 * s, y: 3 * s, width: 14 * s, height: 15 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 3 * s, y: 3 * s, width: 14 * s, height: 15 * s)).stroke()
            // Book binding
            white.setFill()
            NSRect(x: 4 * s, y: 3 * s, width: 2 * s, height: 15 * s).fill()
            // Yellow "?"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 11 * s),
                .foregroundColor: yellow
            ]
            let str = NSAttributedString(string: "?", attributes: attrs)
            str.draw(at: NSPoint(x: 8 * s, y: 4 * s))

        case .run:
            // Classic Run window with green arrow
            gray.setFill()
            NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s)).stroke()
            // Blue titlebar
            blue.setFill()
            NSRect(x: 3 * s, y: 13 * s, width: 14 * s, height: 2 * s).fill()
            // Green triangle arrow
            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: 5 * s, y: 6 * s))
            arrow.line(to: NSPoint(x: 12 * s, y: 9 * s))
            arrow.line(to: NSPoint(x: 5 * s, y: 12 * s))
            arrow.close()
            green.setFill()
            arrow.fill()
            black.setStroke()
            arrow.lineWidth = 0.8 * s
            arrow.stroke()

        case .shutDown, .forceQuit:
            // Classic beige desktop computer with red power sign
            gray.setFill()
            NSRect(x: 3 * s, y: 6 * s, width: 14 * s, height: 10 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 3 * s, y: 6 * s, width: 14 * s, height: 10 * s)).stroke()
            // Screen
            red.setFill()
            NSRect(x: 5 * s, y: 8 * s, width: 10 * s, height: 6 * s).fill()
            // Stand
            darkGray.setFill()
            NSRect(x: 7 * s, y: 3 * s, width: 6 * s, height: 3 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 7 * s, y: 3 * s, width: 6 * s, height: 3 * s)).stroke()

        case .logOff, .lock:
            // Classic gold key
            let keyHead = NSBezierPath(ovalIn: NSRect(x: 3 * s, y: 9 * s, width: 8 * s, height: 8 * s))
            yellow.setFill()
            keyHead.fill()
            black.setStroke()
            keyHead.lineWidth = 1 * s
            keyHead.stroke()
            // Key hole
            white.setFill()
            NSBezierPath(ovalIn: NSRect(x: 5.5 * s, y: 11.5 * s, width: 3 * s, height: 3 * s)).fill()
            // Key shaft
            let shaft = NSBezierPath()
            shaft.move(to: NSPoint(x: 10 * s, y: 11 * s))
            shaft.line(to: NSPoint(x: 17 * s, y: 5 * s))
            shaft.line(to: NSPoint(x: 16 * s, y: 4 * s))
            shaft.line(to: NSPoint(x: 15 * s, y: 6 * s))
            black.setStroke()
            shaft.lineWidth = 1.5 * s
            shaft.stroke()

        case .myComputer:
            // Classic 95 Desktop PC
            gray.setFill()
            NSRect(x: 3 * s, y: 7 * s, width: 14 * s, height: 9 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 3 * s, y: 7 * s, width: 14 * s, height: 9 * s)).stroke()
            // Blue monitor screen
            lightBlue.setFill()
            NSRect(x: 5 * s, y: 9 * s, width: 10 * s, height: 5 * s).fill()
            // Desktop horizontal unit
            darkGray.setFill()
            NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 4 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 4 * s)).stroke()
            // Floppy drive slot
            black.setFill()
            NSRect(x: 11 * s, y: 4.5 * s, width: 5 * s, height: 1 * s).fill()

        case .terminal:
            // MS-DOS prompt
            black.setFill()
            NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s).fill()
            white.setStroke()
            NSBezierPath(rect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s)).stroke()
            // "C:>"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 7 * s),
                .foregroundColor: yellow
            ]
            NSAttributedString(string: "C:\\>", attributes: attrs).draw(at: NSPoint(x: 3.5 * s, y: 5 * s))

        case .internet:
            // Blue globe with white grid
            let globe = NSBezierPath(ovalIn: NSRect(x: 3 * s, y: 3 * s, width: 14 * s, height: 14 * s))
            lightBlue.setFill()
            globe.fill()
            black.setStroke()
            globe.lineWidth = 1 * s
            globe.stroke()
            white.setStroke()
            let eq = NSBezierPath()
            eq.move(to: NSPoint(x: 3 * s, y: 10 * s))
            eq.line(to: NSPoint(x: 17 * s, y: 10 * s))
            eq.stroke()

        case .email:
            // White envelope with red stamp
            white.setFill()
            NSRect(x: 2 * s, y: 5 * s, width: 16 * s, height: 10 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 2 * s, y: 5 * s, width: 16 * s, height: 10 * s)).stroke()
            let flap = NSBezierPath()
            flap.move(to: NSPoint(x: 2 * s, y: 15 * s))
            flap.line(to: NSPoint(x: 10 * s, y: 9 * s))
            flap.line(to: NSPoint(x: 18 * s, y: 15 * s))
            flap.stroke()
            red.setFill()
            NSRect(x: 14 * s, y: 11 * s, width: 3 * s, height: 3 * s).fill()

        default:
            yellow.setFill()
            NSRect(x: 3 * s, y: 3 * s, width: 14 * s, height: 14 * s).fill()
            black.setStroke()
            NSBezierPath(rect: NSRect(x: 3 * s, y: 3 * s, width: 14 * s, height: 14 * s)).stroke()
        }
    }

    // MARK: - Windows XP Luna Style (Soft dimensional gradients, warm yellow, Luna blue, gloss)
    private func drawWinXPIcon(type: SystemIconType, in rect: NSRect) {
        let s = rect.width / 20.0
        let goldGrad = NSGradient(starting: NSColor(srgbRed: 1.0, green: 0.88, blue: 0.35, alpha: 1.0),
                                  ending: NSColor(srgbRed: 0.95, green: 0.65, blue: 0.05, alpha: 1.0))!
        let blueGrad = NSGradient(starting: NSColor(srgbRed: 0.35, green: 0.65, blue: 1.0, alpha: 1.0),
                                  ending: NSColor(srgbRed: 0.1, green: 0.35, blue: 0.8, alpha: 1.0))!
        let redGrad = NSGradient(starting: NSColor(srgbRed: 1.0, green: 0.35, blue: 0.25, alpha: 1.0),
                                 ending: NSColor(srgbRed: 0.75, green: 0.1, blue: 0.05, alpha: 1.0))!

        switch type {
        case .documents, .programs, .folder, .openFolder:
            // Rich golden XP folder
            let back = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s), xRadius: 2 * s, yRadius: 2 * s)
            goldGrad.draw(in: back, angle: -90)

            // Front flap with dimensional gloss
            let front = NSBezierPath()
            front.move(to: NSPoint(x: 1 * s, y: 3 * s))
            front.line(to: NSPoint(x: 3.5 * s, y: 11 * s))
            front.line(to: NSPoint(x: 18.5 * s, y: 11 * s))
            front.line(to: NSPoint(x: 17 * s, y: 3 * s))
            front.close()
            goldGrad.draw(in: front, angle: -80)
            NSColor(srgbRed: 0.8, green: 0.5, blue: 0.0, alpha: 0.6).setStroke()
            front.lineWidth = 1 * s
            front.stroke()

        case .recentDocuments:
            // Golden folder with clock badge
            self.drawWinXPIcon(type: .documents, in: rect)
            let clockRect = NSRect(x: 10 * s, y: 2 * s, width: 8 * s, height: 8 * s)
            NSColor.white.setFill()
            NSBezierPath(ovalIn: clockRect).fill()
            blueGrad.draw(in: NSBezierPath(ovalIn: clockRect), angle: -90)
            NSColor.white.setStroke()
            let clockHands = NSBezierPath()
            clockHands.move(to: NSPoint(x: 14 * s, y: 6 * s))
            clockHands.line(to: NSPoint(x: 14 * s, y: 8.5 * s))
            clockHands.move(to: NSPoint(x: 14 * s, y: 6 * s))
            clockHands.line(to: NSPoint(x: 16 * s, y: 6 * s))
            clockHands.lineWidth = 1 * s
            clockHands.stroke()

        case .pictures:
            self.drawWinXPIcon(type: .documents, in: rect)
            // Photo easel badge
            let photoRect = NSRect(x: 7 * s, y: 4 * s, width: 10 * s, height: 7 * s)
            NSColor.white.setFill()
            photoRect.fill()
            NSColor(srgbRed: 0.2, green: 0.7, blue: 0.2, alpha: 1.0).setFill()
            NSRect(x: 8 * s, y: 5 * s, width: 8 * s, height: 3 * s).fill()
            NSColor(srgbRed: 0.4, green: 0.7, blue: 1.0, alpha: 1.0).setFill()
            NSRect(x: 8 * s, y: 8 * s, width: 8 * s, height: 2 * s).fill()

        case .music:
            self.drawWinXPIcon(type: .documents, in: rect)
            // Note badge
            let note = NSBezierPath()
            note.move(to: NSPoint(x: 10 * s, y: 4 * s))
            note.line(to: NSPoint(x: 10 * s, y: 10 * s))
            note.line(to: NSPoint(x: 15 * s, y: 12 * s))
            note.line(to: NSPoint(x: 15 * s, y: 6 * s))
            redGrad.draw(in: note, angle: -90)

        case .myComputer:
            // Dimensional CRT monitor with Bliss rolling hills
            let mon = NSBezierPath(roundedRect: NSRect(x: 3 * s, y: 6 * s, width: 14 * s, height: 11 * s), xRadius: 2 * s, yRadius: 2 * s)
            NSColor(srgbRed: 0.85, green: 0.88, blue: 0.92, alpha: 1.0).setFill()
            mon.fill()
            // Bliss screen
            let screen = NSBezierPath(roundedRect: NSRect(x: 4.5 * s, y: 8 * s, width: 11 * s, height: 7 * s), xRadius: 1 * s, yRadius: 1 * s)
            NSColor(srgbRed: 0.2, green: 0.65, blue: 0.95, alpha: 1.0).setFill()
            screen.fill()
            // Green hill
            let hill = NSBezierPath()
            hill.move(to: NSPoint(x: 4.5 * s, y: 8 * s))
            hill.curve(to: NSPoint(x: 15.5 * s, y: 8 * s), controlPoint1: NSPoint(x: 8 * s, y: 12 * s), controlPoint2: NSPoint(x: 13 * s, y: 9 * s))
            NSColor(srgbRed: 0.3, green: 0.75, blue: 0.2, alpha: 1.0).setFill()
            hill.fill()
            // Base
            blueGrad.draw(in: NSRect(x: 7 * s, y: 2 * s, width: 6 * s, height: 4 * s), angle: -90)

        case .controlPanel:
            // Blue folder with silver tools
            let back = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s), xRadius: 2 * s, yRadius: 2 * s)
            blueGrad.draw(in: back, angle: -90)
            // Hammer/wrench crossed
            NSColor(white: 0.9, alpha: 1.0).setStroke()
            let tools = NSBezierPath()
            tools.move(to: NSPoint(x: 5 * s, y: 5 * s))
            tools.line(to: NSPoint(x: 15 * s, y: 13 * s))
            tools.move(to: NSPoint(x: 15 * s, y: 5 * s))
            tools.line(to: NSPoint(x: 5 * s, y: 13 * s))
            tools.lineWidth = 2 * s
            tools.stroke()

        case .search:
            // Golden folder with silver magnifying glass
            self.drawWinXPIcon(type: .documents, in: rect)
            let lens = NSBezierPath(ovalIn: NSRect(x: 8 * s, y: 6 * s, width: 8 * s, height: 8 * s))
            NSColor(srgbRed: 0.8, green: 0.95, blue: 1.0, alpha: 0.7).setFill()
            lens.fill()
            NSColor(white: 0.4, alpha: 1.0).setStroke()
            lens.lineWidth = 1.5 * s
            lens.stroke()
            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 14.5 * s, y: 7.5 * s))
            handle.line(to: NSPoint(x: 18.5 * s, y: 3.5 * s))
            NSColor(srgbRed: 0.6, green: 0.3, blue: 0.1, alpha: 1.0).setStroke()
            handle.lineWidth = 2.5 * s
            handle.stroke()

        case .help:
            // 3D glossy blue sphere with white "?"
            let sphere = NSBezierPath(ovalIn: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s))
            blueGrad.draw(in: sphere, angle: -45)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 12 * s),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: "?", attributes: attrs)
            str.draw(at: NSPoint(x: 7 * s, y: 3.5 * s))

        case .run:
            // XP dialog with curved lime-green arrow
            let card = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s), xRadius: 2 * s, yRadius: 2 * s)
            NSColor.white.setFill()
            card.fill()
            NSColor(srgbRed: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).setFill()
            NSRect(x: 2 * s, y: 13 * s, width: 16 * s, height: 3 * s).fill()
            // Green arrow
            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: 5 * s, y: 6 * s))
            arrow.line(to: NSPoint(x: 12 * s, y: 9 * s))
            arrow.line(to: NSPoint(x: 5 * s, y: 12 * s))
            arrow.close()
            NSColor(srgbRed: 0.25, green: 0.8, blue: 0.2, alpha: 1.0).setFill()
            arrow.fill()

        case .shutDown, .forceQuit:
            // Red circular power button
            let circle = NSBezierPath(ovalIn: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s))
            redGrad.draw(in: circle, angle: -45)
            NSColor.white.setStroke()
            let arc = NSBezierPath()
            arc.appendArc(withCenter: NSPoint(x: 10 * s, y: 10 * s), radius: 5 * s, startAngle: 120, endAngle: 60)
            arc.lineWidth = 1.8 * s
            arc.stroke()
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 10 * s, y: 10 * s))
            line.line(to: NSPoint(x: 10 * s, y: 15 * s))
            line.lineWidth = 1.8 * s
            line.stroke()

        case .logOff, .lock:
            // Gold key on blue circle
            let circle = NSBezierPath(ovalIn: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s))
            blueGrad.draw(in: circle, angle: -45)
            goldGrad.draw(in: NSRect(x: 6 * s, y: 8 * s, width: 8 * s, height: 4 * s), angle: 0)

        case .internet:
            // Vibrant blue 3D globe with atmospheric orbit
            let globe = NSBezierPath(ovalIn: NSRect(x: 2.5 * s, y: 2.5 * s, width: 15 * s, height: 15 * s))
            blueGrad.draw(in: globe, angle: -45)
            // Orbit ring
            let orbit = NSBezierPath(ovalIn: NSRect(x: 1 * s, y: 6 * s, width: 18 * s, height: 8 * s))
            NSColor.white.setStroke()
            orbit.lineWidth = 1.2 * s
            orbit.stroke()

        case .email:
            // Stamped envelope
            let env = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 12 * s), xRadius: 1.5 * s, yRadius: 1.5 * s)
            NSColor(srgbRed: 0.96, green: 0.96, blue: 0.94, alpha: 1.0).setFill()
            env.fill()
            NSColor(white: 0.7, alpha: 1.0).setStroke()
            env.lineWidth = 1 * s
            env.stroke()
            // Red stamp
            redGrad.draw(in: NSRect(x: 13 * s, y: 11 * s, width: 3.5 * s, height: 3.5 * s), angle: -45)

        case .terminal:
            // XP Command Prompt
            let box = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 14 * s), xRadius: 2 * s, yRadius: 2 * s)
            NSColor(srgbRed: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).setFill()
            box.fill()
            blueGrad.draw(in: NSRect(x: 2 * s, y: 14 * s, width: 16 * s, height: 3 * s), angle: 0)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 7 * s),
                .foregroundColor: NSColor.white
            ]
            NSAttributedString(string: ">_", attributes: attrs).draw(at: NSPoint(x: 4 * s, y: 6 * s))

        default:
            goldGrad.draw(in: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s), angle: -45)
        }
    }

    // MARK: - Windows 7 Aero Style (Translucent glass, high specular, widescreen LCD)
    private func drawWin7Icon(type: SystemIconType, in rect: NSRect) {
        let s = rect.width / 20.0
        let glassCyanGrad = NSGradient(starting: NSColor(srgbRed: 0.3, green: 0.8, blue: 1.0, alpha: 0.95),
                                       ending: NSColor(srgbRed: 0.05, green: 0.45, blue: 0.8, alpha: 0.95))!

        switch type {
        case .documents, .folder, .programs, .openFolder:
            // Aero translucent folder with cyan glass spine
            let folder = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 14 * s), xRadius: 2 * s, yRadius: 2 * s)
            glassCyanGrad.draw(in: folder, angle: -60)
            // Specular shine on top edge
            NSColor.white.withAlphaComponent(0.4).setFill()
            NSRect(x: 2 * s, y: 15 * s, width: 16 * s, height: 1.5 * s).fill()

        case .myComputer:
            // Modern widescreen LCD monitor with silver stand
            let mon = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 6 * s, width: 16 * s, height: 11 * s), xRadius: 1.5 * s, yRadius: 1.5 * s)
            NSColor(srgbRed: 0.15, green: 0.15, blue: 0.18, alpha: 1.0).setFill()
            mon.fill()
            glassCyanGrad.draw(in: NSRect(x: 3.5 * s, y: 7.5 * s, width: 13 * s, height: 8 * s), angle: -45)
            // Aluminum stand
            NSColor(srgbRed: 0.75, green: 0.78, blue: 0.82, alpha: 1.0).setFill()
            NSRect(x: 7 * s, y: 2 * s, width: 6 * s, height: 4 * s).fill()

        case .controlPanel, .settings:
            // Aero Glass Control Gears
            let gear1 = NSBezierPath(ovalIn: NSRect(x: 3 * s, y: 5 * s, width: 10 * s, height: 10 * s))
            glassCyanGrad.draw(in: gear1, angle: -45)
            let gear2 = NSBezierPath(ovalIn: NSRect(x: 9 * s, y: 3 * s, width: 8 * s, height: 8 * s))
            NSGradient(starting: NSColor(white: 0.9, alpha: 1.0), ending: NSColor(white: 0.5, alpha: 1.0))!.draw(in: gear2, angle: -45)

        case .search:
            // Aero Glass magnifying glass
            let lens = NSBezierPath(ovalIn: NSRect(x: 4 * s, y: 7 * s, width: 10 * s, height: 10 * s))
            NSColor(srgbRed: 0.5, green: 0.85, blue: 1.0, alpha: 0.35).setFill()
            lens.fill()
            NSColor.white.setStroke()
            lens.lineWidth = 1.5 * s
            lens.stroke()
            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 12.5 * s, y: 8.5 * s))
            handle.line(to: NSPoint(x: 17.5 * s, y: 3.5 * s))
            NSColor(srgbRed: 0.3, green: 0.35, blue: 0.4, alpha: 1.0).setStroke()
            handle.lineWidth = 2.5 * s
            handle.stroke()

        case .shutDown, .forceQuit:
            // Aero glowing red power button
            let p = NSBezierPath(ovalIn: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s))
            NSGradient(starting: NSColor(srgbRed: 1.0, green: 0.3, blue: 0.2, alpha: 0.95),
                       ending: NSColor(srgbRed: 0.6, green: 0.05, blue: 0.05, alpha: 0.95))!.draw(in: p, angle: -45)
            NSColor.white.setStroke()
            let arc = NSBezierPath()
            arc.appendArc(withCenter: NSPoint(x: 10 * s, y: 10 * s), radius: 5 * s, startAngle: 120, endAngle: 60)
            arc.lineWidth = 1.5 * s
            arc.stroke()
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 10 * s, y: 10 * s))
            line.line(to: NSPoint(x: 10 * s, y: 14.5 * s))
            line.lineWidth = 1.5 * s
            line.stroke()

        default:
            glassCyanGrad.draw(in: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s), angle: -45)
        }
    }

    // MARK: - Windows 8.1 Metro Style (Pure white geometric flat silhouettes for colored tiles)
    private func drawWin8Icon(type: SystemIconType, in rect: NSRect) {
        let s = rect.width / 20.0
        NSColor.white.setStroke()
        NSColor.white.setFill()

        switch type {
        case .documents, .recentDocuments, .file:
            let doc = NSBezierPath()
            doc.move(to: NSPoint(x: 4 * s, y: 3 * s))
            doc.line(to: NSPoint(x: 4 * s, y: 17 * s))
            doc.line(to: NSPoint(x: 12 * s, y: 17 * s))
            doc.line(to: NSPoint(x: 16 * s, y: 13 * s))
            doc.line(to: NSPoint(x: 16 * s, y: 3 * s))
            doc.close()
            doc.lineWidth = 1.5 * s
            doc.stroke()
            NSRect(x: 6 * s, y: 12 * s, width: 5 * s, height: 1.5 * s).fill()
            NSRect(x: 6 * s, y: 9 * s, width: 8 * s, height: 1.5 * s).fill()
            NSRect(x: 6 * s, y: 6 * s, width: 6 * s, height: 1.5 * s).fill()

        case .programs, .folder, .openFolder:
            let folder = NSBezierPath()
            folder.move(to: NSPoint(x: 3 * s, y: 4 * s))
            folder.line(to: NSPoint(x: 3 * s, y: 14 * s))
            folder.line(to: NSPoint(x: 8 * s, y: 14 * s))
            folder.line(to: NSPoint(x: 10 * s, y: 16 * s))
            folder.line(to: NSPoint(x: 17 * s, y: 16 * s))
            folder.line(to: NSPoint(x: 17 * s, y: 4 * s))
            folder.close()
            folder.lineWidth = 1.5 * s
            folder.stroke()

        case .controlPanel, .settings:
            // Clean Metro 8-toothed gear
            let gear = NSBezierPath(ovalIn: NSRect(x: 5 * s, y: 5 * s, width: 10 * s, height: 10 * s))
            gear.lineWidth = 2 * s
            gear.stroke()
            for i in 0..<8 {
                let angle = CGFloat(i) * (.pi / 4.0)
                let cx = 10 * s + cos(angle) * 6.5 * s
                let cy = 10 * s + sin(angle) * 6.5 * s
                NSRect(x: cx - 1.2 * s, y: cy - 1.2 * s, width: 2.4 * s, height: 2.4 * s).fill()
            }

        case .search, .goToPath:
            let lens = NSBezierPath(ovalIn: NSRect(x: 4 * s, y: 7 * s, width: 9 * s, height: 9 * s))
            lens.lineWidth = 1.8 * s
            lens.stroke()
            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 11.5 * s, y: 8.5 * s))
            handle.line(to: NSPoint(x: 16.5 * s, y: 3.5 * s))
            handle.lineWidth = 2.2 * s
            handle.stroke()

        case .shutDown, .forceQuit:
            let arc = NSBezierPath()
            arc.appendArc(withCenter: NSPoint(x: 10 * s, y: 10 * s), radius: 6 * s, startAngle: 120, endAngle: 60)
            arc.lineWidth = 2 * s
            arc.stroke()
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 10 * s, y: 10 * s))
            line.line(to: NSPoint(x: 10 * s, y: 16 * s))
            line.lineWidth = 2 * s
            line.stroke()

        case .terminal:
            let term = NSBezierPath(rect: NSRect(x: 3 * s, y: 4 * s, width: 14 * s, height: 12 * s))
            term.lineWidth = 1.5 * s
            term.stroke()
            let p = NSBezierPath()
            p.move(to: NSPoint(x: 5 * s, y: 12 * s))
            p.line(to: NSPoint(x: 8 * s, y: 10 * s))
            p.line(to: NSPoint(x: 5 * s, y: 8 * s))
            p.lineWidth = 1.5 * s
            p.stroke()

        default:
            NSRect(x: 4 * s, y: 4 * s, width: 12 * s, height: 12 * s).fill()
        }
    }

    // MARK: - Windows 10 Modern Style (Refined MDL2 glyphs, precise lines)
    private func drawWin10Icon(type: SystemIconType, in rect: NSRect) {
        // Windows 10 uses similar clean glyphs with slightly finer stroke
        self.drawWin8Icon(type: type, in: rect)
    }

    // MARK: - Windows 11 Fluent Style (Soft rounded geometry, colorful gradients)
    private func drawWin11Icon(type: SystemIconType, in rect: NSRect) {
        let s = rect.width / 20.0
        let fluentBlue = NSGradient(starting: NSColor(srgbRed: 0.15, green: 0.65, blue: 1.0, alpha: 1.0),
                                    ending: NSColor(srgbRed: 0.05, green: 0.35, blue: 0.9, alpha: 1.0))!
        let fluentYellow = NSGradient(starting: NSColor(srgbRed: 1.0, green: 0.85, blue: 0.25, alpha: 1.0),
                                      ending: NSColor(srgbRed: 0.95, green: 0.6, blue: 0.1, alpha: 1.0))!

        switch type {
        case .documents, .folder, .programs, .openFolder:
            let back = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 4 * s, width: 16 * s, height: 13 * s), xRadius: 3 * s, yRadius: 3 * s)
            fluentYellow.draw(in: back, angle: -45)
            let flap = NSBezierPath(roundedRect: NSRect(x: 2 * s, y: 3 * s, width: 16 * s, height: 9 * s), xRadius: 3 * s, yRadius: 3 * s)
            fluentBlue.draw(in: flap, angle: -45)

        case .controlPanel, .settings:
            let g = NSBezierPath(ovalIn: NSRect(x: 3 * s, y: 3 * s, width: 14 * s, height: 14 * s))
            fluentBlue.draw(in: g, angle: -45)

        case .shutDown, .forceQuit:
            let circle = NSBezierPath(ovalIn: NSRect(x: 2 * s, y: 2 * s, width: 16 * s, height: 16 * s))
            NSColor(white: 0.2, alpha: 1.0).setFill()
            circle.fill()
            NSColor.white.setStroke()
            let arc = NSBezierPath()
            arc.appendArc(withCenter: NSPoint(x: 10 * s, y: 10 * s), radius: 5 * s, startAngle: 120, endAngle: 60)
            arc.lineWidth = 1.6 * s
            arc.stroke()
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 10 * s, y: 10 * s))
            line.line(to: NSPoint(x: 10 * s, y: 15 * s))
            line.lineWidth = 1.6 * s
            line.stroke()

        default:
            self.drawWinXPIcon(type: type, in: rect)
        }
    }
}
