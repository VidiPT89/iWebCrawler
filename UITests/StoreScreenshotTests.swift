import XCTest

/// Walks through the app on a simulator and keeps a screenshot of each screen for the App Store.
/// Run: xcodebuild test -scheme iWebCrawler -destination '<simulator>' -only-testing:iWebCrawlerUITests
/// The language comes from the TEST_RUNNER_STORE_LANGUAGE environment variable (pt-PT by default).
final class StoreScreenshotTests: XCTestCase {
    @MainActor
    func testStoreScreenshots() throws {
        let language = ProcessInfo.processInfo.environment["STORE_LANGUAGE"] ?? "pt-PT"
        let portuguese = language == "pt-PT"
        let app = XCUIApplication()
        app.launchArguments = ["-language", language, "-appearance", "dark", "-speed", "1", "-reducedMotion", "NO", "-followLinks", "NO"]
        app.launch()

        let explore = app.buttons["explore.toggle"]
        XCTAssertTrue(explore.waitForExistence(timeout: 15), "The workspace never appeared after the introduction")
        sleep(2)
        keep(app, "1-demo")

        explore.tap()
        sleep(5)
        keep(app, "2-exploring")
        sleep(10)

        app.segmentedControls.buttons[portuguese ? "Mapa" : "Map"].tap()
        sleep(2)
        keep(app, "3-map")

        app.segmentedControls.buttons[portuguese ? "Descobertas" : "Discoveries"].tap()
        let check = app.buttons["links.check"]
        if check.waitForExistence(timeout: 5), check.isEnabled { check.tap(); sleep(12) }
        keep(app, "4-discoveries")

        app.buttons["settings.open"].tap()
        sleep(2)
        keep(app, "5-settings")
    }

    @MainActor
    private func keep(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
