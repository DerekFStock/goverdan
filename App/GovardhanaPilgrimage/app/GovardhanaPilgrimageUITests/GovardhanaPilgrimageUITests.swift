import XCTest

@MainActor
final class GovardhanaPilgrimageUITests: XCTestCase {
    private let sectionID = "story.radhakunda.manifestation"
    private let storyTitle = "The Story of Śrī Rādhā-kuṇḍa"
    private let sectionTitle = "The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa"
    private let workID = "work.radha-kundastaka"
    private let workTitle = "Śrī Rādhā-kuṇḍāṣṭakam"

    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    private func openStory(_ app: XCUIApplication) {
        app.buttons["home.story"].tap()
        XCTAssertTrue(app.navigationBars[storyTitle].waitForExistence(timeout: 5))
        app.buttons["story.toc.section.\(sectionID)"].tap()
        XCTAssertTrue(app.navigationBars[sectionTitle].waitForExistence(timeout: 5))
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 12) {
        for _ in 0..<attempts where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
    }

    func testAppLaunchesWithRealContentAndApprovedDestinations() {
        let app = launch()
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["home.story"].exists)
        XCTAssertTrue(app.buttons["home.library"].exists)
        XCTAssertTrue(app.buttons["home.search"].exists)
        XCTAssertTrue(app.buttons["home.bookmarks"].exists)
        XCTAssertTrue(app.staticTexts[storyTitle].exists)
        XCTAssertTrue(app.staticTexts["Twenty-Verse Rādhā-kuṇḍa Manifestation Account"].exists)
        XCTAssertFalse(app.staticTexts["Śrīmad-Bhāgavatam 10.36"].exists)
    }

    func testNeutralMappedPassageOpensExactWitnessAndBackRestoresNormalizedPassage() throws {
        let app = launch()
        guard app.staticTexts["Neutral Fixture Story"].waitForExistence(timeout: 2) else {
            throw XCTSkip("Neutral witness UI test runs against the fixture database build")
        }
        app.buttons["home.story"].tap()
        app.buttons["story.toc.section.section.fixture.opening"].tap()
        let citation = app.buttons["story.citation.citation.fixture.opening"]
        reveal(citation, in: app)
        citation.tap()
        XCTAssertTrue(app.staticTexts["Passage 2"].waitForExistence(timeout: 5))
        let witness = app.buttons["source.original-witness"]
        XCTAssertTrue(witness.waitForExistence(timeout: 5))
        witness.tap()
        XCTAssertTrue(app.navigationBars["Neutral Original Witness"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Printed page 1"].exists)
        XCTAssertTrue(app.staticTexts["PDF page index 2"].exists)
        app.navigationBars["Neutral Original Witness"].buttons["Neutral Fixture Work"].tap()
        XCTAssertTrue(app.navigationBars["Neutral Fixture Work"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Passage 2"].exists)
        app.buttons["Contents"].tap()
        app.buttons["Passage 1"].tap()
        XCTAssertTrue(app.staticTexts["Passage 1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["source.original-witness"].exists)
    }

    func testTask010AcceptanceStoryCitationSurroundingReturnSearchAndBookmark() {
        let app = launch()
        openStory(app)
        let origin = app.descendants(matching: .any)["story.block.rk-manifestation-block-01-dharma-challenge"]
        XCTAssertTrue(origin.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "narma-dharmokti-raṅgaiḥ")).firstMatch.exists)

        let citation = app.buttons["story.citation.citation.rk.manifestation.rka.1.challenge"]
        reveal(citation, in: app)
        citation.tap()
        XCTAssertTrue(app.navigationBars[workTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cited passage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Passage Verse 1"].exists)
        app.buttons["Contents"].tap()
        app.buttons["Passage Verse 2"].tap()
        XCTAssertTrue(app.staticTexts["Passage Verse 2"].waitForExistence(timeout: 5))
        app.buttons["Return to Story"].tap()
        XCTAssertTrue(app.navigationBars[sectionTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(origin.waitForExistence(timeout: 5))
        XCTAssertTrue(origin.isHittable)

        app.navigationBars[sectionTitle].buttons[storyTitle].tap()
        app.navigationBars[storyTitle].buttons["Home"].tap()
        app.buttons["home.search"].tap()
        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText("narma-dharmokti\n")
        let sourceResult = app.buttons["search.result.search.source.representation.radha-kundastaka.1.project-reading-v1"]
        XCTAssertTrue(sourceResult.waitForExistence(timeout: 5))
        sourceResult.tap()
        XCTAssertTrue(app.navigationBars[workTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Search result"].waitForExistence(timeout: 5))
        let bookmark = app.buttons["source.bookmark"]
        if bookmark.label == "Remove Bookmark" { bookmark.tap() }
        bookmark.tap()
        XCTAssertEqual("Remove Bookmark", bookmark.label)
    }

    func testRangeCitationDisplaysCompleteLocusOpensStartAndReturnsExactly() {
        let app = launch()
        openStory(app)
        let origin = app.descendants(matching: .any)["story.block.rk-manifestation-block-01-dharma-challenge"]
        let citation = app.buttons["story.citation.citation.rk.manifestation.rkma.1-2"]
        reveal(citation, in: app)
        XCTAssertEqual(
            "Citation: Twenty-Verse Rādhā-kuṇḍa Manifestation Account Verses 1–2",
            citation.label
        )
        citation.tap()
        XCTAssertTrue(app.navigationBars["Twenty-Verse Rādhā-kuṇḍa Manifestation Account"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cited passage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Passage Verse 1"].exists)
        app.buttons["Return to Story"].tap()
        XCTAssertTrue(app.navigationBars[sectionTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(origin.waitForExistence(timeout: 5))
        XCTAssertTrue(origin.isHittable)
    }

    func testSrimadBhagavatamBackgroundRangeAndNativeScriptReader() {
        let app = launch()
        openStory(app)
        let origin = app.descendants(matching: .any)["story.block.rk-manifestation-block-01-dharma-challenge"]
        let citation = app.buttons["story.citation.citation.rk.manifestation.sb.10.36.1-15"]
        reveal(citation, in: app)
        XCTAssertEqual("Citation: Śrīmad-Bhāgavatam Verses 1–15", citation.label)
        citation.tap()
        XCTAssertTrue(app.navigationBars["Śrīmad-Bhāgavatam"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Passage 10.36.1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "श्री बादरायणिरुवाच")).firstMatch.exists)
        XCTAssertEqual("passage.srimad-bhagavatam.10.36.1", app.buttons["source.bookmark"].value as? String)
        app.buttons["Return to Story"].tap()
        XCTAssertTrue(origin.waitForExistence(timeout: 5))
        XCTAssertTrue(origin.isHittable)
    }

    func testLibraryExposesOnlyPackagedWorksAndIndependentReader() {
        let app = launch()
        app.buttons["home.library"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["library.work.\(workID)"].exists)
        XCTAssertFalse(app.buttons["library.work.work.stavavali"].exists)
        app.buttons["library.work.\(workID)"].tap()
        XCTAssertTrue(app.navigationBars[workTitle].waitForExistence(timeout: 5))
        app.buttons["work.toc.passage.passage.radha-kundastaka.1"].tap()
        let verseTwo = app.staticTexts["Passage Verse 2"]
        for _ in 0..<5 where !verseTwo.isHittable { app.swipeUp() }
        XCTAssertTrue(verseTwo.waitForExistence(timeout: 5))
        XCTAssertEqual("passage.radha-kundastaka.2", app.buttons["source.bookmark"].value as? String)
        XCTAssertFalse(app.buttons["Return to Story"].exists)
        XCTAssertFalse(app.buttons["source.original-witness"].exists)
    }

    func testSearchBackRestoresExactQueryAndResults() {
        let app = launch()
        app.buttons["home.search"].tap()
        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText("narma-dharmokti\n")
        let sourceResult = app.buttons["search.result.search.source.representation.radha-kundastaka.1.project-reading-v1"]
        let storyResult = app.buttons["search.result.search.story.rk-manifestation-block-01-dharma-challenge"]
        XCTAssertTrue(sourceResult.waitForExistence(timeout: 5))
        XCTAssertTrue(storyResult.exists)
        sourceResult.tap()
        XCTAssertTrue(app.navigationBars[workTitle].waitForExistence(timeout: 5))
        app.navigationBars[workTitle].buttons["Search"].tap()
        XCTAssertTrue(sourceResult.waitForExistence(timeout: 5))
        XCTAssertEqual("narma-dharmokti", field.value as? String)
    }

    func testSourceBookmarkAndReadingPositionSurviveColdRelaunch() {
        let app = launch()
        app.buttons["home.library"].tap()
        app.buttons["library.work.\(workID)"].tap()
        app.buttons["work.toc.passage.passage.radha-kundastaka.2"].tap()
        let bookmark = app.buttons["source.bookmark"]
        XCTAssertTrue(bookmark.waitForExistence(timeout: 5))
        if bookmark.label == "Remove Bookmark" { bookmark.tap() }
        bookmark.tap()
        app.terminate()
        app.launch()
        app.buttons["home.bookmarks"].tap()
        let item = app.buttons["bookmarks.item.source:passage.radha-kundastaka.2"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
        XCTAssertTrue(app.staticTexts["Bookmarked passage"].waitForExistence(timeout: 5))
        app.buttons["source.bookmark"].tap()
    }

    func testWorkScopedSearchReturnsCanonicalSourceOnly() {
        let app = launch()
        app.buttons["home.library"].tap()
        app.buttons["library.work.\(workID)"].tap()
        app.buttons["work.search"].tap()
        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText("narma-dharmokti\n")
        XCTAssertTrue(app.buttons["search.result.search.source.representation.radha-kundastaka.1.project-reading-v1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["search.result.search.story.rk-manifestation-block-01-dharma-challenge"].exists)
    }
}
