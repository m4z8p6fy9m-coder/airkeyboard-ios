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

    func validated() throws -> Theme {
        guard schemaVersion == 1 else { throw ThemeError.version(schemaVersion) }
        guard minimumIOS == 18 else { throw ThemeError.invalid("minimumIOS must be 18") }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name.count <= 60, description.count <= 500,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        else { throw ThemeError.invalid("name or description length") }
        for value in [background, key, primary, secondary, accent, pressed, border] {
            guard value.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
            else { throw ThemeError.invalid("colors must use #RRGGBB") }
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
