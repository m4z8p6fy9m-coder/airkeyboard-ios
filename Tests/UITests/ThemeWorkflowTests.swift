import XCTest

final class ThemeWorkflowTests: XCTestCase {
    func testCreateSaveAndReloadThemeInTheRealApp() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let themes = app.tabBars.buttons["Themes"]
        XCTAssertTrue(themes.waitForExistence(timeout: 15))
        themes.tap()
        let create = app.navigationBars["Themes"].buttons["New theme"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        create.tap()
        let preview = app.switches["studio.preview.dark"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        XCTAssertEqual(preview.value as? String, "1")
        preview.tap()
        XCTAssertEqual(preview.value as? String, "0", "Preview must switch without reloading the editor")
        let studio = XCTAttachment(screenshot: app.screenshot())
        studio.name = "Theme Studio light preview"
        studio.lifetime = .keepAlways
        add(studio)
        preview.tap()
        XCTAssertEqual(preview.value as? String, "1")
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        let title = "CI Theme " + String(UUID().uuidString.prefix(8))
        name.tap()
        let existing = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + title + "\n")
        let save = app.navigationBars["Keyboard Studio"].buttons["Save & apply"]
        XCTAssertTrue(save.isHittable)
        save.tap()
        let confirmation = app.alerts["Theme saved & applied"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        confirmation.buttons["Done"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(themes.waitForExistence(timeout: 15))
        themes.tap()
        let saved = app.staticTexts[title]
        for _ in 0..<10 {
            if saved.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(saved.isHittable, "The saved theme must survive app termination and relaunch")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Saved theme after app relaunch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
