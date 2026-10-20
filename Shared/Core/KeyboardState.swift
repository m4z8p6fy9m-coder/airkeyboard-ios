import Foundation

struct KeyboardState: Equatable {
    enum Page { case letters, numbers, symbols }
    enum Shift { case off, once, locked }
    var page: Page = .letters
    var shift: Shift = .once
    mutating func toggleShift(lock: Bool = false) {
        shift = lock ? .locked : (shift == .off ? .once : .off)
    }
    mutating func character(_ value: String) -> String {
        let result = page == .letters && shift != .off ? value.uppercased() : value
        if page == .letters && shift == .once { shift = .off }
        return result
    }
    func rows(layout: KeyboardLayout) -> [[String]] {
        switch page {
        case .letters:
            return (layout == .qwerty ? ["qwertyuiop", "asdfghjkl", "zxcvbnm"] :
                    ["qwertzuiop", "asdfghjkl", "yxcvbnm"]).map { $0.map(String.init) }
        case .numbers: return [Array("1234567890"), Array("-/:;()$&@\""), Array(".,?!'")].map { $0.map(String.init) }
        case .symbols: return [Array("[]{}#%^*+="), Array("_\\|~<>€£¥•"), Array(".,?!'")].map { $0.map(String.init) }
        }
    }
}
