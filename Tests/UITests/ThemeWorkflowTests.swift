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
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        let title = "CI Theme " + UUID().uuidString.prefix(8)
        name.tap()
        let existing = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + title)
        let save = app.buttons["Save & apply"]
        for _ in 0..<10 {
            if save.isHittable { break }
            app.swipeUp()
        }
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
