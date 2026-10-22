import Foundation

enum StarterThemes {
    static let all: [Theme] = [
        make(1, "Dark Glass", "Quiet contrast. A hint of mint.", "121B22", "29353F", "F0F6F7", "9DAEBB", "83E5CE"),
        make(2, "Minimal", "Less color, more clarity.", "181818", "303030", "FFFFFF", "BBBBBB", "DDDDDD"),
        make(3, "Retro Tech", "Phosphor green, reimagined.", "101D15", "1C3424", "C8F5CC", "9DBBA1", "9BE378"),
        make(4, "Midnight", "Deep blue for late ideas.", "101426", "262D4C", "ECEEFF", "ABB4D9", "A5B4FF"),
        make(5, "Soft Light", "Warm paper and clear ink.", "EAE8E1", "FFFFFF", "1D292B", "485E61", "17695D", light: true),
        make(6, "Futuristic", "A measured electric violet.", "1A1229", "362849", "F6EDFF", "C5AEDB", "D4A5FA")
    ] + premium
    static var defaultTheme: Theme { all[0] }
    private static func make(_ n: Int, _ name: String, _ description: String, _ bg: String,
                             _ key: String, _ text: String, _ secondary: String, _ accent: String,
                             light: Bool = false) -> Theme {
        Theme(id: UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!,
              name: name, description: description, background: "#" + bg, key: "#" + key,
              primary: "#" + text, secondary: "#" + secondary, accent: "#" + accent,
              pressed: light ? "#B9DCD4" : "#4A5A65", border: light ? "#C4CECA" : "#4C5D69",
              appearance: light ? .light : .dark)
    }

    /// Adapted from the supplied PremiumKeyboardThemes.swift / design-tokens.json.
    static let premium: [Theme] = [
        Theme(id: UUID(uuidString: "00000000-0000-4000-8000-000000000007")!,
              name: "Cupertino Native", description: "Familiar light and dark, following your system.",
              background: "#252629", key: "#44464B",
              primary: "#F5F5F7", secondary: "#C5C7CD", accent: "#0A84FF",
              pressed: "#5A5D63", border: "#54565C",
              cornerRadius: 5.5, borderWidth: 0.0, font: .standard,
              rendering: ThemeRendering(surface: .solid, specialKey: "#34363B",
                  light: ThemePalette(background: "#D5D8E0", key: "#FFFFFF",
                      specialKey: "#C3C9D4", primary: "#17191D", secondary: "#555B66",
                      border: "#BCC2CD", pressed: "#D3D8E1", accent: "#0A84FF"), followsSystem: true)),
        Theme(id: UUID(uuidString: "00000000-0000-4000-8000-000000000008")!,
              name: "Nord Minimal", description: "Quiet blue-gray with an icy accent.",
              background: "#2E3440", key: "#3B4252",
              primary: "#ECEFF4", secondary: "#D8DEE9", accent: "#88C0D0",
              pressed: "#515D73", border: "#4C566A",
              cornerRadius: 6.0, borderWidth: 0.5, font: .standard,
              rendering: ThemeRendering(surface: .solid, specialKey: "#434C5E",
                  light: nil, followsSystem: false)),
        Theme(id: UUID(uuidString: "00000000-0000-4000-8000-000000000009")!,
              name: "Slate Glass", description: "Restrained material with an accessible opaque fallback.",
              background: "#1D242E", key: "#FFFFFF21",
              primary: "#F7F9FC", secondary: "#D0D8E2", accent: "#9AC8F5",
              pressed: "#FFFFFF38", border: "#FFFFFF2B",
              cornerRadius: 7.0, borderWidth: 0.5, font: .standard,
              rendering: ThemeRendering(surface: .glass, specialKey: "#FFFFFF30",
                  light: nil, followsSystem: false)),
        Theme(id: UUID(uuidString: "00000000-0000-4000-8000-000000000010")!,
              name: "Midnight OLED", description: "True black background and distinct graphite keys.",
              background: "#000000", key: "#1A1A1A",
              primary: "#F2F2F7", secondary: "#B8B8BD", accent: "#0A84FF",
              pressed: "#303030", border: "#353535",
              cornerRadius: 6.0, borderWidth: 0.5, font: .standard,
              rendering: ThemeRendering(surface: .solid, specialKey: "#252525",
                  light: nil, followsSystem: false)),
    ]
}
