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
    /// Merge missing new presets without changing saved designs, IDs or favorites.
    func addingPremiumThemes() throws -> ThemeLibrary {
        var result = self
        let existing = Set(themes.map(\.id))
        let missing = StarterThemes.premium.filter { !existing.contains($0.id) }
        // Keep a full user library intact; do not evict a design to make room for a preset.
        result.themes.append(contentsOf: missing.prefix(max(0, 200 - themes.count)))
        return try result.validated()
    }

    func catalog(query: String = "", favoritesOnly: Bool = false, order: ThemeSortOrder = .catalog) -> [Theme] {
        let saved = Set(themes.map(\.id))
        let all = themes + StarterThemes.premium.filter { !saved.contains($0.id) }
        func normalized(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        }
        let terms = normalized(query).split(whereSeparator: \.isWhitespace)
        let filtered = all.filter { theme in
            (!favoritesOnly || favorites.contains(theme.id)) && terms.allSatisfy {
                normalized(theme.name + " " + theme.description).contains($0)
            }
        }
        guard order != .catalog else { return filtered }
        return filtered.sorted { lhs, rhs in
            if order == .favorites && favorites.contains(lhs.id) != favorites.contains(rhs.id) {
                return favorites.contains(lhs.id)
            }
            let left = normalized(lhs.name), right = normalized(rhs.name)
            return left == right ? lhs.id.uuidString < rhs.id.uuidString : left < right
        }
    }

    func saving(_ theme: Theme) throws -> ThemeLibrary {
        let valid = try theme.validated()
        var result = self
        if let index = result.themes.firstIndex(where: { $0.id == valid.id }) { result.themes[index] = valid }
        else {
            guard result.themes.count < 200 else {
                throw ThemeError.invalid("library is full (200 themes). Export and delete a design before adding another.")
            }
            result.themes.append(valid)
        }
        return try result.validated()
    }

    func validated() throws -> ThemeLibrary {
        guard !themes.isEmpty, themes.count <= 200, Set(themes.map(\.id)).count == themes.count,
              favorites.isSubset(of: Set(themes.map(\.id))) else { throw ThemeError.invalid("library integrity") }
        for theme in themes { _ = try theme.validated() }
        return self
    }
}

enum ThemeSortOrder: String, CaseIterable { case catalog, name, favorites }
