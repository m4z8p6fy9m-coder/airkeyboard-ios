import SwiftUI
import WidgetKit

@MainActor final class AppModel: ObservableObject {
    @Published var library = ThemeLibrary()
    @Published var settings = SharedSettings()
    @Published var error: String?
    @Published var ready = false
    @Published var busy = false
    @Published var sharingAvailable = false
    let audio = SoundEngine()
    nonisolated private static func libraryStore() throws -> JSONStore<ThemeLibrary> {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: true)
        return JSONStore(url: root.appendingPathComponent("themes.json"), validate: { try $0.validated() })
    }
    func load() async {
        do {
            library = try await Task.detached {
                let store = try Self.libraryStore()
                let existing = try store.load() ?? ThemeLibrary()
                let upgraded = try existing.addingPremiumThemes()
                if upgraded != existing { try store.save(upgraded) }
                return upgraded
            }.value
            settings = try await SharedStore.load()
            sharingAvailable = try await SharedStore.isSharingAvailable()
        } catch { self.error = error.localizedDescription }
        ready = true
        await audio.prepare()
    }
    func refreshSettings() async {
        do {
            settings = try await SharedStore.load()
            sharingAvailable = try await SharedStore.isSharingAvailable()
        } catch { self.error = error.localizedDescription }
    }
    private func persist(_ value: ThemeLibrary) async throws {
        try await Task.detached { try Self.libraryStore().save(value) }.value
        library = value
    }
    func save(_ theme: Theme) async -> Bool {
        guard !busy else { return false }
        busy = true; defer { busy = false }
        do {
            try await persist(library.saving(theme))
            return true
        } catch { self.error = error.localizedDescription; return false }
    }
    @discardableResult func apply(_ theme: Theme) async -> Bool {
        do {
            let valid = try theme.validated()
            settings = try await SharedStore.update { $0.theme = valid; $0.sound.pack = valid.soundPack }
            refreshWidgets()
            return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func sound(_ value: SoundPreferences) async {
        do {
            let valid = try value.validated()
            settings = try await SharedStore.update { $0.sound = valid }
            if !valid.audible { audio.stop() }
            refreshWidgets()
        } catch { self.error = error.localizedDescription }
    }
    func favorite(_ id: UUID) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        var next = library
        if !next.favorites.insert(id).inserted { next.favorites.remove(id) }
        do { try await persist(next) } catch { self.error = error.localizedDescription }
    }
    func delete(_ id: UUID) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        var next = library
        next.themes.removeAll { $0.id == id }; next.favorites.remove(id)
        do {
            try await persist(next)
            if settings.theme.id == id { await apply(StarterThemes.defaultTheme) }
        } catch { self.error = error.localizedDescription }
    }
    func importTheme(_ url: URL) async {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            var theme = try await Task.detached { try ThemeCodec.read(url) }.value
            // Import as a new item; an untrusted identifier never overwrites a saved theme.
            theme.id = UUID()
            _ = await save(theme)
        } catch { self.error = "Import failed: \(error.localizedDescription)" }
    }
    func previewSound(_ pack: SoundPack) {
        var value = settings.sound; value.enabled = true; value.pack = pack
        if !audio.play(value) { error = audio.failure }
    }
    private func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
    }
}
