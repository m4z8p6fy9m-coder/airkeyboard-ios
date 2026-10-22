import XCTest
#if SWIFT_PACKAGE
@testable import AirKeyboardCore
#endif

final class ThemeTests: XCTestCase {
    func testAllStarterThemesRoundTrip() throws {
        XCTAssertEqual(StarterThemes.all.count, 10)
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
    func testLegacyThemeWithoutRenderingStillDecodes() throws {
        let data = try ThemeCodec.encode(StarterThemes.defaultTheme)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "rendering")
        let decoded = try ThemeCodec.decode(JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.rendering)
        XCTAssertEqual(decoded, StarterThemes.defaultTheme)
    }
    func testCupertinoResolvesBothPalettesWithoutMutatingDefinition() throws {
        let theme = StarterThemes.premium[0]
        XCTAssertEqual(theme.resolved(dark: false).key, "#FFFFFF")
        XCTAssertEqual(theme.resolved(dark: false).rendering?.specialKey, "#C3C9D4")
        XCTAssertEqual(theme.resolved(dark: true).background, "#252629")
        XCTAssertEqual(theme.key, "#44464B")
        XCTAssertEqual(try ThemeCodec.decode(ThemeCodec.encode(theme)), theme)
        for fixed in StarterThemes.premium.dropFirst() {
            XCTAssertEqual(fixed.resolved(dark: false), fixed.resolved(dark: true))
        }
    }
    func testGlassValidationAndLegacyAlphaRejection() throws {
        let glass = StarterThemes.premium[2]
        XCTAssertEqual(glass.rendering?.surface, .glass)
        XCTAssertEqual(glass.key, "#FFFFFF21")
        XCTAssertNoThrow(try glass.validated())
        var solid = glass; solid.rendering?.surface = .solid
        XCTAssertThrowsError(try solid.validated())
        var invalid = glass; invalid.rendering?.specialKey = "#NOTHEX00"
        XCTAssertThrowsError(try invalid.validated())
        invalid = StarterThemes.premium[0]; invalid.rendering?.light?.key = "#BAD"
        XCTAssertThrowsError(try invalid.validated())
        invalid = StarterThemes.premium[0]; invalid.rendering?.light = nil
        XCTAssertThrowsError(try invalid.validated())
    }
    func testPresetUpgradePreservesCustomizationsAndFavorites() throws {
        var library = ThemeLibrary()
        library.themes = Array(StarterThemes.all.prefix(6))
        var custom = StarterThemes.premium[0]; custom.name = "My custom Cupertino"
        library.themes.append(custom); library.favorites.insert(custom.id)
        let upgraded = try library.addingPremiumThemes()
        XCTAssertEqual(upgraded.themes.count, 10)
        XCTAssertEqual(upgraded.themes.first(where: { $0.id == custom.id }), custom)
        XCTAssertEqual(upgraded.favorites, library.favorites)
        XCTAssertEqual(try upgraded.addingPremiumThemes(), upgraded)
    }
    func testPresetUpgradeDoesNotEvictFullUserLibrary() throws {
        var library = ThemeLibrary()
        library.themes = (0..<200).map { _ in
            var theme = StarterThemes.defaultTheme; theme.id = UUID(); return theme
        }
        XCTAssertEqual(try library.addingPremiumThemes(), library)
    }
    func testHexParserRejectsWhitespaceAndUnicodeAndUsesAlphaLast() throws {
        for value in ["#000000\n", " #FFFFFF", "#FFFFFF ", "#１２３４５６", "#GGGGGG", "#FFF", "FFFFFF"] {
            XCTAssertNil(ThemeColor(hex: value), value)
            XCTAssertThrowsError(try Theme.validateColor(value, allowsAlpha: true))
        }
        let color = try XCTUnwrap(ThemeColor(hex: "#FFFFFF21"))
        XCTAssertEqual(color.red, 1)
        XCTAssertEqual(color.alpha, 33.0 / 255, accuracy: 0.000001)
        XCTAssertThrowsError(try Theme.validateColor("#FFFFFFFF"))
        XCTAssertNoThrow(try Theme.validateColor("#aabbcc"))
    }
    func testContrastKnownReferenceValuesAndGlassFallback() throws {
        let black = try XCTUnwrap(ThemeColor(hex: "#000000"))
        let white = try XCTUnwrap(ThemeColor(hex: "#FFFFFF"))
        XCTAssertEqual(black.contrast(with: white), 21, accuracy: 0.000001)
        XCTAssertEqual(white.contrast(with: white), 1, accuracy: 0.000001)
        var low = StarterThemes.defaultTheme; low.primary = low.key; low.pressed = low.key
        XCTAssertEqual(try XCTUnwrap(low.minimumPrimaryContrast(dark: true)), 1, accuracy: 0.000001)
        XCTAssertGreaterThan(try XCTUnwrap(StarterThemes.premium[2].minimumPrimaryContrast(dark: true)), 4.5)
    }
    func testAdaptiveColorEditingPreservesOtherBranchAndRoundTrips() throws {
        var value = StarterThemes.premium[0]
        let originalDark = value.key
        value.setColor("#FAFAFA", role: .key, dark: false)
        value.setColor("#CCCCCC", role: .specialKey, dark: false)
        XCTAssertEqual(value.color(.key, dark: false), "#FAFAFA")
        XCTAssertEqual(value.key, originalDark)
        XCTAssertEqual(value.color(.specialKey, dark: false), "#CCCCCC")
        XCTAssertEqual(value.rendering?.followsSystem, true)
        value.setColor("#333333", role: .key, dark: true)
        XCTAssertEqual(value.key, "#333333")
        XCTAssertEqual(value.color(.key, dark: false), "#FAFAFA")
        XCTAssertEqual(try ThemeCodec.decode(ThemeCodec.encode(value)), value)
    }
    func testCatalogSearchIsCaseAndDiacriticInsensitiveAndMatchesAllTerms() throws {
        var library = ThemeLibrary()
        var custom = StarterThemes.defaultTheme; custom.id = UUID(); custom.name = "Café Key"; custom.description = "Quiet blue"
        library = try library.saving(custom)
        XCTAssertEqual(library.catalog(query: "  CAFE   BLUE ").map(\.id), [custom.id])
        XCTAssertTrue(library.catalog(query: "cafe missing").isEmpty)
        XCTAssertEqual(library.catalog(query: "NORD").first?.name, "Nord Minimal")
        XCTAssertEqual(library.catalog(query: "  ").count, library.themes.count)
    }
    func testCatalogFavoritesSortingAndFullCapacityVirtualPresets() {
        var library = ThemeLibrary()
        let chosen = StarterThemes.premium[2]
        library.favorites.insert(chosen.id)
        XCTAssertEqual(library.catalog(favoritesOnly: true).map(\.id), [chosen.id])
        XCTAssertEqual(library.catalog(order: .favorites).first?.id, chosen.id)
        XCTAssertEqual(library.catalog(order: .name).map(\.name),
                       ["Cupertino Native", "Dark Glass", "Futuristic", "Midnight", "Midnight OLED",
                        "Minimal", "Nord Minimal", "Retro Tech", "Slate Glass", "Soft Light"])
        library.themes = Array(library.themes.prefix(6)); library.favorites = []
        XCTAssertEqual(library.catalog().count, 10)
        XCTAssertEqual(library.themes.count, 6, "Viewing the catalog must not mutate storage")
    }
    func testFullLibraryCanUpdateButCannotEvictOrAppend() throws {
        var library = ThemeLibrary()
        library.themes = (0..<200).map { _ in
            var theme = StarterThemes.defaultTheme; theme.id = UUID(); return theme
        }
        let before = library
        var existing = library.themes[0]; existing.name = "Updated"
        XCTAssertEqual(try library.saving(existing).themes.count, 200)
        XCTAssertThrowsError(try library.saving(StarterThemes.premium[0]))
        XCTAssertEqual(library, before)
    }
}
