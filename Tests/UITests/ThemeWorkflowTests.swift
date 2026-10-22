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
        func expectPreviewValue(_ value: String) {
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: preview)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed,
                           "Preview must expose \(value) without reloading; observed \(String(describing: preview.value))")
        }
        expectPreviewValue("1")
        // SwiftUI can expose the whole labeled row as the switch's accessibility frame.
        // Tap the trailing control area rather than the label/spacing at its center.
        preview.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        expectPreviewValue("0")
        let studio = XCTAttachment(screenshot: app.screenshot())
        studio.name = "Theme Studio light preview"
        studio.lifetime = .keepAlways
        add(studio)
        // SwiftUI can expose the whole labeled row as the switch's accessibility frame.
        // Tap the trailing control area rather than the label/spacing at its center.
        preview.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        expectPreviewValue("1")
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
    func testSearchFindsSlateAndExposesAccessibilityPreview() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Themes"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Themes"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("Slate\n")
        let edit = app.buttons["theme.edit.00000000-0000-4000-8000-000000000009"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        for _ in 0..<5 { if edit.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(edit.isHittable); edit.tap()
        let opaque = app.switches["studio.preview.opaque"]
        for _ in 0..<8 { if opaque.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(opaque.isHittable)
        opaque.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: opaque)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed)
        XCTAssertTrue(app.staticTexts["studio.contrast.ratio"].exists)
    }
    func testInvalidNameDisablesSaveBeforePersistence() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Themes"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Themes"].tap()
        app.navigationBars["Themes"].buttons["New theme"].tap()
        let name = app.textFields["studio.name"]
        for _ in 0..<8 { if name.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(name.isHittable); name.tap()
        let text = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count) + "\n")
        let save = app.navigationBars["Keyboard Studio"].buttons["Save & apply"]
        let disabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [disabled], timeout: 3), .completed)
    }
}
