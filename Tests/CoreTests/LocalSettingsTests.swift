import XCTest
#if SWIFT_PACKAGE
@testable import AirKeyboardCore
#endif

final class LocalSettingsTests: XCTestCase {
    func testMissingGroupUsesPrivateStorageWithoutClaimingSharing() throws {
        let support = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: support) }
        let location = SettingsLocation.resolve(sharedContainer: nil, applicationSupport: support)
        XCTAssertFalse(location.isShared)
        let store = JSONStore<SharedSettings>(url: location.url, validate: { try $0.validated() })
        var settings = SharedSettings(); settings.theme = StarterThemes.all[3]
        try store.save(settings)
        XCTAssertEqual(try store.load(), settings)
    }
    func testAuthorizedGroupUsesTheSharedContainer() {
        let support = URL(fileURLWithPath: "/private-app")
        let group = URL(fileURLWithPath: "/authorized-group")
        let location = SettingsLocation.resolve(sharedContainer: group, applicationSupport: support)
        XCTAssertTrue(location.isShared)
        XCTAssertEqual(location.url, group.appendingPathComponent("settings.json"))
    }
    func testLocalTargetsRemainIsolated() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = SettingsLocation.resolve(sharedContainer: nil, applicationSupport: root.appendingPathComponent("app"))
        let keyboard = SettingsLocation.resolve(sharedContainer: nil, applicationSupport: root.appendingPathComponent("keyboard"))
        let first = JSONStore<SharedSettings>(url: app.url, validate: { try $0.validated() })
        let second = JSONStore<SharedSettings>(url: keyboard.url, validate: { try $0.validated() })
        var value = SharedSettings(); value.theme = StarterThemes.all[4]
        try first.save(value)
        XCTAssertNil(try second.load())
        try second.save(SharedSettings())
        XCTAssertEqual(try first.load(), value)
        XCTAssertEqual(try second.load(), SharedSettings())
    }
}
