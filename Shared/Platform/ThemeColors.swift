import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: String) {
        let value = ThemeColor(hex: hex)
        self.init(red: CGFloat(value?.red ?? 0), green: CGFloat(value?.green ?? 0),
                  blue: CGFloat(value?.blue ?? 0), alpha: CGFloat(value?.alpha ?? 1))
    }
}
extension Color {
    init(hex: String) { self.init(uiColor: UIColor(hex: hex)) }
    var rgbaHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }
    var rgbHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            .getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

/// Surface-only rendering; label, hit targets, geometry and actions stay in the existing views.
struct ThemeKeySurface: View {
    let theme: Theme
    let special: Bool
    let pressed: Bool
    var forceOpaque = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private var glass: Bool { theme.rendering?.surface == .glass }
    private var fill: String {
        if glass && (reduceTransparency || forceOpaque) {
            return pressed ? Theme.opaqueGlassPressed : special ? Theme.opaqueGlassSpecialKey : Theme.opaqueGlassKey
        }
        return pressed ? theme.pressed : special ? (theme.rendering?.specialKey ?? theme.key) : theme.key
    }
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.cornerRadius)
        Group {
            if glass && !reduceTransparency && !forceOpaque {
                shape.fill(.ultraThinMaterial)
                    .environment(\.colorScheme, theme.appearance == .light ? .light : .dark)
                    .overlay(shape.fill(Color(hex: fill)))
            } else {
                shape.fill(Color(hex: fill))
            }
        }
        .overlay(shape.stroke(Color(hex: glass && (reduceTransparency || forceOpaque) ? Theme.opaqueGlassBorder : theme.border),
                              lineWidth: contrast == .increased ? max(1, theme.borderWidth) : theme.borderWidth))
        .allowsHitTesting(false)
    }
}
