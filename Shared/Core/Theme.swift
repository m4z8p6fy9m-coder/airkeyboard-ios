import Foundation

enum ThemeError: LocalizedError {
    case invalid(String), tooLarge, version(Int)
    var errorDescription: String? {
        switch self {
        case .invalid(let reason): return "Invalid theme: \(reason)"
        case .tooLarge: return "Theme packages must be at most 64 KB."
        case .version(let value): return "Theme version \(value) is unsupported. Use a version 1 package."
        }
    }
}

enum SoundPack: String, Codable, CaseIterable, Sendable {
    case tactile, mechanical, pop, digital, silent
    var title: String {
        switch self {
        case .tactile: return "Soft tactile"
        case .mechanical: return "Mechanical"
        case .pop: return "Soft pop"
        case .digital: return "Digital"
        case .silent: return "Silent"
        }
    }
}
enum KeyFont: String, Codable, CaseIterable, Sendable { case rounded, standard, monospaced }
enum ThemeAppearance: String, Codable, CaseIterable, Sendable { case dark, light }
enum KeyboardLayout: String, Codable, CaseIterable, Sendable { case qwerty, qwertz }

enum ThemeSurface: String, Codable, Sendable { case solid, glass }

/// Optional v1 rendering metadata. Legacy packages omit it and keep their original palette.
struct ThemePalette: Codable, Equatable, Sendable {
    var background: String
    var key: String
    var specialKey: String
    var primary: String
    var secondary: String
    var border: String
    var pressed: String
    var accent: String

    func validate(surface: ThemeSurface) throws {
        for value in [background, primary, secondary, accent] {
            try Theme.validateColor(value)
        }
        for value in [key, specialKey, border, pressed] {
            try Theme.validateColor(value, allowsAlpha: surface == .glass)
        }
    }
}

struct ThemeRendering: Codable, Equatable, Sendable {
    var surface: ThemeSurface
    var specialKey: String
    var light: ThemePalette?
    var followsSystem: Bool
}

struct Theme: Codable, Equatable, Identifiable, Sendable {
    var schemaVersion = 1
    var minimumIOS = 18
    var id: UUID
    var name: String
    var description: String
    var background: String
    var key: String
    var primary: String
    var secondary: String
    var accent: String
    var pressed: String
    var border: String
    var cornerRadius: Double = 8
    var spacing: Double = 5
    var padding: Double = 6
    var borderWidth: Double = 0.5
    var font: KeyFont = .rounded
    var appearance: ThemeAppearance = .dark
    var layout: KeyboardLayout = .qwerty
    var soundPack: SoundPack = .tactile

    var rendering: ThemeRendering?

    /// Resolved copies are for drawing only; persist/export the original adaptive definition.
    func resolved(dark: Bool) -> Theme {
        guard rendering?.followsSystem == true else { return self }
        var result = self
        result.appearance = dark ? .dark : .light
        if !dark, let light = rendering?.light {
            result.background = light.background; result.key = light.key
            result.primary = light.primary; result.secondary = light.secondary
            result.accent = light.accent; result.pressed = light.pressed; result.border = light.border
            result.rendering?.specialKey = light.specialKey
        }
        return result
    }

    static let opaqueGlassKey = "#343B47"
    static let opaqueGlassSpecialKey = "#414957"
    static let opaqueGlassPressed = "#59616D"
    static let opaqueGlassBorder = "#7C8593"

    static func validateColor(_ value: String, allowsAlpha: Bool = false) throws {
        guard let color = ThemeColor(hex: value), allowsAlpha || color.alpha == 1 && value.utf8.count == 7 else {
            throw ThemeError.invalid("colors must use #RRGGBB; glass surfaces also accept #RRGGBBAA")
        }
    }

    func color(_ role: ThemeColorRole, dark: Bool) -> String {
        let value = resolved(dark: dark)
        switch role {
        case .background: return value.background
        case .key: return value.key
        case .primary: return value.primary
        case .secondary: return value.secondary
        case .accent: return value.accent
        case .pressed: return value.pressed
        case .border: return value.border
        case .specialKey: return value.rendering?.specialKey ?? value.key
        }
    }

    /// Edit the displayed adaptive branch without flattening or replacing the other branch.
    mutating func setColor(_ value: String, role: ThemeColorRole, dark: Bool) {
        if rendering?.followsSystem == true && !dark && rendering?.light != nil {
            switch role {
            case .background: rendering?.light?.background = value
            case .key: rendering?.light?.key = value
            case .primary: rendering?.light?.primary = value
            case .secondary: rendering?.light?.secondary = value
            case .accent: rendering?.light?.accent = value
            case .pressed: rendering?.light?.pressed = value
            case .border: rendering?.light?.border = value
            case .specialKey: rendering?.light?.specialKey = value
            }
            return
        }
        switch role {
        case .background: background = value
        case .key: key = value
        case .primary: primary = value
        case .secondary: secondary = value
        case .accent: accent = value
        case .pressed: pressed = value
        case .border: border = value
        case .specialKey: rendering?.specialKey = value
        }
    }

    /// Glass is assessed against its opaque accessibility fallback, not an unknown blur backdrop.
    func minimumPrimaryContrast(dark: Bool) -> Double? {
        let value = resolved(dark: dark)
        let glass = rendering?.surface == .glass
        let fills = glass ? [Self.opaqueGlassKey, Self.opaqueGlassSpecialKey, Self.opaqueGlassPressed]
                          : [value.key, value.rendering?.specialKey ?? value.key, value.pressed]
        guard let text = ThemeColor(hex: value.primary) else { return nil }
        let colors = fills.compactMap { ThemeColor(hex: $0) }
        guard colors.count == fills.count else { return nil }
        return colors.map { text.contrast(with: $0) }.min()
    }

    func validated() throws -> Theme {
        guard schemaVersion == 1 else { throw ThemeError.version(schemaVersion) }
        guard minimumIOS == 18 else { throw ThemeError.invalid("minimumIOS must be 18") }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name.count <= 60, description.count <= 500,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        else { throw ThemeError.invalid("name or description length") }
        for value in [background, primary, secondary, accent] { try Self.validateColor(value) }
        for value in [key, pressed, border] {
            try Self.validateColor(value, allowsAlpha: rendering?.surface == .glass)
        }
        if let rendering {
            try Self.validateColor(rendering.specialKey, allowsAlpha: rendering.surface == .glass)
            try rendering.light?.validate(surface: rendering.surface)
            if rendering.followsSystem && rendering.light == nil {
                throw ThemeError.invalid("adaptive rendering needs a light palette")
            }
        }
        for (value, range) in [(cornerRadius, 0.0...20), (spacing, 2.0...8),
                               (padding, 2.0...12), (borderWidth, 0.0...2)] {
            guard value.isFinite, range.contains(value) else { throw ThemeError.invalid("geometry out of range") }
        }
        return self
    }
}

enum ThemeCodec {
    static let maximumBytes = 65_536
    static func decode(_ data: Data) throws -> Theme {
        guard data.count <= maximumBytes else { throw ThemeError.tooLarge }
        // Check the version before decoding enums, so future formats yield a useful error.
        struct Header: Decodable { let schemaVersion: Int }
        let version = try JSONDecoder().decode(Header.self, from: data).schemaVersion
        guard version == 1 else { throw ThemeError.version(version) }
        return try JSONDecoder().decode(Theme.self, from: data).validated()
    }
    static func encode(_ theme: Theme) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(theme.validated())
    }
    static func read(_ url: URL) throws -> Theme {
        let size = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard size.isRegularFile == true else { throw ThemeError.invalid("not a regular file") }
        guard let count = size.fileSize, count <= maximumBytes else { throw ThemeError.tooLarge }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try decode(handle.read(upToCount: maximumBytes + 1) ?? Data())
    }
}


enum ThemeColorRole: String, CaseIterable { case background, key, primary, secondary, accent, pressed, border, specialKey }

/// Strict ASCII hex parsing shared by validation, platform drawing and numerical contrast checks.
struct ThemeColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    init?(hex: String) {
        let bytes = Array(hex.utf8)
        guard [7, 9].contains(bytes.count), bytes.first == 35,
              bytes.dropFirst().allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }),
              let number = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        let rgba = bytes.count == 9
        let rgb = rgba ? number >> 8 : number
        red = Double((rgb >> 16) & 255) / 255
        green = Double((rgb >> 8) & 255) / 255
        blue = Double(rgb & 255) / 255
        alpha = rgba ? Double(number & 255) / 255 : 1
    }
    private var luminance: Double {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
    func contrast(with other: ThemeColor) -> Double {
        (max(luminance, other.luminance) + 0.05) / (min(luminance, other.luminance) + 0.05)
    }
}
