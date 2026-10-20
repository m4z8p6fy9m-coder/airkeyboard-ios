import XCTest
#if SWIFT_PACKAGE
@testable import AirKeyboardCore
#endif

final class StateTests: XCTestCase {
    func testPersistenceAndRecovery() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = JSONStore<ThemeLibrary>(url: folder.appendingPathComponent("library.json"), validate: { try $0.validated() })
        XCTAssertNil(try store.load())
        let initial = ThemeLibrary()
        try store.save(initial)
        var changed = initial; changed.themes[0].name = "Changed"
        try store.save(changed)
        XCTAssertEqual(try store.load(), changed)
        try Data("corrupt".utf8).write(to: store.url)
        XCTAssertEqual(try store.load(), initial)
        try Data("corrupt".utf8).write(to: store.backup)
        XCTAssertThrowsError(try store.load())
    }
    func testInvalidSavePreservesLastValue() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = JSONStore<SharedSettings>(url: folder.appendingPathComponent("settings.json"), validate: { try $0.validated() })
        try store.save(SharedSettings())
        var bad = SharedSettings(); bad.sound.volume = 2
        XCTAssertThrowsError(try store.save(bad))
        XCTAssertEqual(try store.load(), SharedSettings())
    }
    func testSoundPreferences() throws {
        var sound = SoundPreferences()
        XCTAssertFalse(sound.audible)
        sound.enabled = true
        XCTAssertTrue(sound.audible)
        sound.pack = .silent
        XCTAssertFalse(sound.audible)
        sound.pack = .pop; sound.volume = 0
        XCTAssertFalse(sound.audible)
        sound.volume = -1
        XCTAssertThrowsError(try sound.validated())
        sound.volume = 1; sound.intensity = .nan
        XCTAssertThrowsError(try sound.validated())
    }
    func testShiftCapsAndLayoutTransitions() {
        var state = KeyboardState()
        XCTAssertEqual(state.character("a"), "A")
        XCTAssertEqual(state.character("b"), "b")
        state.toggleShift(lock: true)
        XCTAssertEqual(state.character("c"), "C")
        XCTAssertEqual(state.character("d"), "D")
        state.toggleShift()
        XCTAssertEqual(state.character("e"), "e")
        state.page = .numbers
        XCTAssertEqual(state.character("1"), "1")
        XCTAssertEqual(state.rows(layout: .qwerty)[0].joined(), "1234567890")
        state.page = .symbols
        XCTAssertTrue(state.rows(layout: .qwerty)[0].contains("#"))
        state.page = .letters
        XCTAssertEqual(state.rows(layout: .qwertz)[0].joined(), "qwertzuiop")
    }
    func testSharedSettingsSerializationAndDefaults() throws {
        let value = SharedSettings()
        XCTAssertEqual(value.theme, StarterThemes.defaultTheme)
        XCTAssertFalse(value.sound.enabled)
        XCTAssertEqual(try JSONDecoder().decode(SharedSettings.self, from: JSONEncoder().encode(value)), value)
    }
}
