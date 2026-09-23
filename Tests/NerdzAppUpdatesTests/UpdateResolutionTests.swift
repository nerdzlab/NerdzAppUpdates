import Testing
@testable import NerdzAppUpdates

@Suite("UpdateResolution")
struct UpdateResolutionTests {
    @Test("A hard update wins over a soft update regardless of order")
    func testWhenHardAndSoftPresentShouldSelectHard() {
        let latest = "3.0.0"
        let results = [
            TestData.success(.softUpdate, "2.5.0"),
            TestData.success(.hardUpdate, latest)
        ]
        let outcome = UpdateResolution.selected(from: results)
        #expect(outcome.presentation == .hardUpdate(latestVersion: latest))
    }

    @Test("A soft update is selected when no hard update is present")
    func testWhenOnlySoftPresentShouldSelectSoft() {
        let latest = "2.5.0"
        let results = [
            TestData.success(.notNeeded, "2.4.0"),
            TestData.success(.softUpdate, latest)
        ]
        let outcome = UpdateResolution.selected(from: results)
        #expect(outcome.presentation == .softUpdate(latestVersion: latest))
    }

    @Test("The first soft update wins when multiple are present")
    func testWhenTwoSoftUpdatesShouldSelectFirst() {
        let firstLatest = "2.5.0"
        let secondLatest = "2.6.0"
        let results = [
            TestData.success(.softUpdate, firstLatest),
            TestData.success(.softUpdate, secondLatest)
        ]
        let outcome = UpdateResolution.selected(from: results)
        #expect(outcome.presentation == .softUpdate(latestVersion: firstLatest))
    }

    @Test("A hard update followed by a soft update still selects hard")
    func testWhenHardThenSoftShouldSelectHard() {
        let latest = "3.0.0"
        let results = [
            TestData.success(.hardUpdate, latest),
            TestData.success(.softUpdate, "2.5.0")
        ]
        let outcome = UpdateResolution.selected(from: results)
        #expect(outcome.presentation == .hardUpdate(latestVersion: latest))
    }

    @Test("No update is presented when nothing is needed")
    func testWhenNothingNeededShouldPresentNone() {
        let results = [TestData.success(.notNeeded, "2.4.0")]
        let outcome = UpdateResolution.selected(from: results)
        #expect(outcome.presentation == .none)
    }

    @Test("Empty results present nothing and select nothing")
    func testWhenNoResultsShouldSelectNil() {
        let outcome = UpdateResolution.selected(from: [])
        #expect(outcome.chosen == nil)
        #expect(outcome.presentation == .none)
    }
}
