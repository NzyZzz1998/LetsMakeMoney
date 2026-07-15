import XCTest

final class M3SmokeUITests: XCTestCase {
    func testTodayCalendarAndSettingsAreReachable() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-test-reset-configuration", "-ui-test-configured"]
        app.launch()
        XCTAssertTrue(app.otherElements["today.amount"].waitForExistence(timeout: 3))
        app.buttons["nav.tab.calendar"].tap()
        XCTAssertTrue(app.staticTexts["calendar.title"].waitForExistence(timeout: 2))
        app.buttons["nav.settings"].tap()
        XCTAssertTrue(app.otherElements["settings.root"].waitForExistence(timeout: 2))
        app.buttons["settings.cancel"].tap()
        XCTAssertFalse(app.otherElements["settings.root"].exists)
    }

    func testFirstLaunchPresentsOnboarding() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-test-reset-configuration"]
        app.launch()
        XCTAssertTrue(app.otherElements["onboarding.root"].waitForExistence(timeout: 3))
    }
}
