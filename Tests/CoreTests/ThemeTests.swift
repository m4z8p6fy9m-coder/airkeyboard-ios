import XCTest
#if SWIFT_PACKAGE
@testable import AirKeyboardCore
#endif

final class ThemeTests: XCTestCase {
    func testAllStarterThemesRoundTrip() throws {
        XCTAssertEqual(StarterThemes.all.count, 6)
        for theme in StarterThemes.all {
            XCTAssertEqual(try ThemeCodec.decode(ThemeCodec.encode(theme)), theme)
        }
    }
    func testMalformedAndOversizedPackages() {
        for data in [Data(), Data("[]".utf8), Data("{broken}".utf8), Data(repeating: 0, count: 65_537)] {
            XCTAssertThrowsError(try ThemeCodec.decode(data))
        }
    }
    func testRejectsInvalidColorsAndGeometry() {
        for value in ["red", "#FFF", "../../file", "#000000FF", "#GGGGGG"] {
            var theme = StarterThemes.defaultTheme; theme.background = value
            XCTAssertThrowsError(try theme.validated())
        }
        for value in [-1.0, 21, .infinity, .nan] {
            var theme = StarterThemes.defaultTheme; theme.cornerRadius = value
            XCTAssertThrowsError(try theme.validated())
        }
    }
    func testUnknownVersionAndEnum() throws {
        let data = try ThemeCodec.encode(StarterThemes.defaultTheme)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["schemaVersion"] = 99
        XCTAssertThrowsError(try ThemeCodec.decode(JSONSerialization.data(withJSONObject: object))) { error in
            guard case ThemeError.version(99) = error else { return XCTFail("Expected version error") }
        }
        object["schemaVersion"] = 1; object["soundPack"] = "untrusted-future-pack"
        XCTAssertThrowsError(try ThemeCodec.decode(JSONSerialization.data(withJSONObject: object)))
    }
    func testImportedUnknownPathsHaveNoEffect() throws {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: ThemeCodec.encode(StarterThemes.defaultTheme)) as? [String: Any])
        object["assetPath"] = "../../secrets"
        let result = try ThemeCodec.decode(JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(result, StarterThemes.defaultTheme) // Unknown metadata is ignored, never opened.
    }
    func testNameAndMinimumCompatibility() {
        var theme = StarterThemes.defaultTheme
        theme.name = "\n"
        XCTAssertThrowsError(try theme.validated())
        theme.name = "Valid"; theme.minimumIOS = 99
        XCTAssertThrowsError(try theme.validated())
    }
    func testFileImportExport() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("design.json")
        let theme = StarterThemes.defaultTheme
        try ThemeCodec.encode(theme).write(to: url)
        XCTAssertEqual(try ThemeCodec.read(url), theme)
        try Data(repeating: 0, count: 65_537).write(to: url)
        XCTAssertThrowsError(try ThemeCodec.read(url))
    }
    func testLibraryIntegrity() throws {
        var library = ThemeLibrary()
        library.themes.append(library.themes[0])
        XCTAssertThrowsError(try library.validated())
        library = ThemeLibrary(); library.favorites.insert(UUID())
        XCTAssertThrowsError(try library.validated())
    }
}
