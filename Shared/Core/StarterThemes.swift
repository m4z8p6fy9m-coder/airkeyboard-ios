import Foundation

enum StarterThemes {
    static let all: [Theme] = [
        make(1, "Dark Glass", "Quiet contrast. A hint of mint.", "121B22", "29353F", "F0F6F7", "9DAEBB", "83E5CE"),
        make(2, "Minimal", "Less color, more clarity.", "181818", "303030", "FFFFFF", "BBBBBB", "DDDDDD"),
        make(3, "Retro Tech", "Phosphor green, reimagined.", "101D15", "1C3424", "C8F5CC", "9DBBA1", "9BE378"),
        make(4, "Midnight", "Deep blue for late ideas.", "101426", "262D4C", "ECEEFF", "ABB4D9", "A5B4FF"),
        make(5, "Soft Light", "Warm paper and clear ink.", "EAE8E1", "FFFFFF", "1D292B", "485E61", "17695D", light: true),
        make(6, "Futuristic", "A measured electric violet.", "1A1229", "362849", "F6EDFF", "C5AEDB", "D4A5FA")
    ]
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
}
