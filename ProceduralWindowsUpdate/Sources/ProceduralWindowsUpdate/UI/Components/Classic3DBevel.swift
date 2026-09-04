import SwiftUI

/// Authentic Windows 95/98/ME 3D beveled borders.
/// Uses pixel-exact integer fills with the canonical Win32 system color palette:
/// #C0C0C0 (Button Face), #FFFFFF (Highlight), #DFDFDF (Light), #808080 (Shadow), #000000 (DkShadow).
public struct Classic3DBevel: ViewModifier {
    public enum Style {
        case raised
        case sunken
        case windowFrame
        case button(isPressed: Bool = false)
        case etched
    }

    public let style: Style

    // Canonical Windows 95/98 GDI Color Palette
    public static let buttonFace = Color(red: 192/255, green: 192/255, blue: 192/255)       // #C0C0C0
    public static let buttonHilight = Color(red: 255/255, green: 255/255, blue: 255/255)    // #FFFFFF
    public static let buttonLight = Color(red: 223/255, green: 223/255, blue: 223/255)      // #DFDFDF
    public static let buttonShadow = Color(red: 128/255, green: 128/255, blue: 128/255)     // #808080
    public static let buttonDkShadow = Color(red: 0/255, green: 0/255, blue: 0/255)         // #000000

    public init(style: Style) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content.overlay(
            Canvas { context, size in
                let w = floor(size.width)
                let h = floor(size.height)
                guard w >= 2, h >= 2 else { return }

                switch style {
                case .windowFrame:
                    // 3-Pixel Classic Windows 95 Dialog Frame (WS_DLGFRAME)
                    // Layer 1 (Outer): #FFFFFF Top/Left, #000000 Bottom/Right
                    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: 1)), with: .color(Self.buttonHilight))
                    context.fill(Path(CGRect(x: 0, y: 0, width: 1, height: h)), with: .color(Self.buttonHilight))
                    context.fill(Path(CGRect(x: 0, y: h - 1, width: w, height: 1)), with: .color(Self.buttonDkShadow))
                    context.fill(Path(CGRect(x: w - 1, y: 0, width: 1, height: h)), with: .color(Self.buttonDkShadow))

                    // Layer 2 (Middle): #DFDFDF Top/Left, #808080 Bottom/Right
                    context.fill(Path(CGRect(x: 1, y: 1, width: max(0, w - 2), height: 1)), with: .color(Self.buttonLight))
                    context.fill(Path(CGRect(x: 1, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonLight))
                    context.fill(Path(CGRect(x: 1, y: h - 2, width: max(0, w - 2), height: 1)), with: .color(Self.buttonShadow))
                    context.fill(Path(CGRect(x: w - 2, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonShadow))

                    // Layer 3 (Inner): #C0C0C0 Face Padding
                    context.fill(Path(CGRect(x: 2, y: 2, width: max(0, w - 4), height: 1)), with: .color(Self.buttonFace))
                    context.fill(Path(CGRect(x: 2, y: 2, width: 1, height: max(0, h - 4))), with: .color(Self.buttonFace))
                    context.fill(Path(CGRect(x: 2, y: h - 3, width: max(0, w - 4), height: 1)), with: .color(Self.buttonFace))
                    context.fill(Path(CGRect(x: w - 3, y: 2, width: 1, height: max(0, h - 4))), with: .color(Self.buttonFace))

                case .sunken:
                    // 2-Pixel Recessed Trough (EDGE_SUNKEN)
                    // Outer: #808080 Top/Left, #FFFFFF Bottom/Right
                    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: 1)), with: .color(Self.buttonShadow))
                    context.fill(Path(CGRect(x: 0, y: 0, width: 1, height: h)), with: .color(Self.buttonShadow))
                    context.fill(Path(CGRect(x: 0, y: h - 1, width: w, height: 1)), with: .color(Self.buttonHilight))
                    context.fill(Path(CGRect(x: w - 1, y: 0, width: 1, height: h)), with: .color(Self.buttonHilight))

                    // Inner: #000000 Top/Left, #DFDFDF Bottom/Right
                    context.fill(Path(CGRect(x: 1, y: 1, width: max(0, w - 2), height: 1)), with: .color(Self.buttonDkShadow))
                    context.fill(Path(CGRect(x: 1, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonDkShadow))
                    context.fill(Path(CGRect(x: 1, y: h - 2, width: max(0, w - 2), height: 1)), with: .color(Self.buttonLight))
                    context.fill(Path(CGRect(x: w - 2, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonLight))

                case .raised:
                    // 2-Pixel Raised Bevel (EDGE_RAISED)
                    // Outer: #FFFFFF Top/Left, #000000 Bottom/Right
                    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: 1)), with: .color(Self.buttonHilight))
                    context.fill(Path(CGRect(x: 0, y: 0, width: 1, height: h)), with: .color(Self.buttonHilight))
                    context.fill(Path(CGRect(x: 0, y: h - 1, width: w, height: 1)), with: .color(Self.buttonDkShadow))
                    context.fill(Path(CGRect(x: w - 1, y: 0, width: 1, height: h)), with: .color(Self.buttonDkShadow))

                    // Inner: #DFDFDF Top/Left, #808080 Bottom/Right
                    context.fill(Path(CGRect(x: 1, y: 1, width: max(0, w - 2), height: 1)), with: .color(Self.buttonLight))
                    context.fill(Path(CGRect(x: 1, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonLight))
                    context.fill(Path(CGRect(x: 1, y: h - 2, width: max(0, w - 2), height: 1)), with: .color(Self.buttonShadow))
                    context.fill(Path(CGRect(x: w - 2, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonShadow))

                case .button(let isPressed):
                    if isPressed {
                        // 2-Pixel Pressed Push Button (Sunken with black outline)
                        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(Self.buttonDkShadow))
                        context.fill(Path(CGRect(x: 1, y: 1, width: max(0, w - 2), height: max(0, h - 2))), with: .color(Self.buttonShadow))
                        context.fill(Path(CGRect(x: 2, y: 2, width: max(0, w - 3), height: max(0, h - 3))), with: .color(Self.buttonFace))
                    } else {
                        // Standard Windows 95 Raised Push Button
                        // Outer: #FFFFFF Top/Left, #000000 Bottom/Right
                        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: 1)), with: .color(Self.buttonHilight))
                        context.fill(Path(CGRect(x: 0, y: 0, width: 1, height: h)), with: .color(Self.buttonHilight))
                        context.fill(Path(CGRect(x: 0, y: h - 1, width: w, height: 1)), with: .color(Self.buttonDkShadow))
                        context.fill(Path(CGRect(x: w - 1, y: 0, width: 1, height: h)), with: .color(Self.buttonDkShadow))

                        // Inner: #DFDFDF Top/Left, #808080 Bottom/Right
                        context.fill(Path(CGRect(x: 1, y: 1, width: max(0, w - 2), height: 1)), with: .color(Self.buttonLight))
                        context.fill(Path(CGRect(x: 1, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonLight))
                        context.fill(Path(CGRect(x: 1, y: h - 2, width: max(0, w - 2), height: 1)), with: .color(Self.buttonShadow))
                        context.fill(Path(CGRect(x: w - 2, y: 1, width: 1, height: max(0, h - 2))), with: .color(Self.buttonShadow))
                    }

                case .etched:
                    // Etched Line (1px Shadow, 1px Highlight)
                    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: 1)), with: .color(Self.buttonShadow))
                    context.fill(Path(CGRect(x: 0, y: 1, width: w, height: 1)), with: .color(Self.buttonHilight))
                }
            }
            // The bevel is decorative; it must never sit in front of the
            // Button's label and intercept its mouse events.
            .allowsHitTesting(false)
        )
    }
}

public extension View {
    func classicBevel(_ style: Classic3DBevel.Style = .raised) -> some View {
        self.modifier(Classic3DBevel(style: style))
    }
}
