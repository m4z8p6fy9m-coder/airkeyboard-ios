import Foundation

struct SoundPreferences: Codable, Equatable, Sendable {
    var enabled = false
    var pack: SoundPack = .tactile
    var volume: Double = 0.35
    // Intensity scales the envelope amplitude; it does not bypass system volume or mute.
    var intensity: Double = 0.7
    func validated() throws -> SoundPreferences {
        guard volume.isFinite, intensity.isFinite, (0...1).contains(volume), (0...1).contains(intensity)
        else { throw ThemeError.invalid("audio levels must be between 0 and 1") }
        return self
    }
    var audible: Bool { enabled && pack != .silent && volume > 0 && intensity > 0 }
}

struct SharedSettings: Codable, Equatable, Sendable {
    var theme = StarterThemes.defaultTheme
    var sound = SoundPreferences()
    func validated() throws -> SharedSettings {
        _ = try theme.validated()
        _ = try sound.validated()
        return self
    }
}

struct ThemeLibrary: Codable, Equatable, Sendable {
    var themes = StarterThemes.all
    var favorites: Set<UUID> = []
    func validated() throws -> ThemeLibrary {
        guard !themes.isEmpty, themes.count <= 200, Set(themes.map(\.id)).count == themes.count,
              favorites.isSubset(of: Set(themes.map(\.id))) else { throw ThemeError.invalid("library integrity") }
        for theme in themes { _ = try theme.validated() }
        return self
    }
}
