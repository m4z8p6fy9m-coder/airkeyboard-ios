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
