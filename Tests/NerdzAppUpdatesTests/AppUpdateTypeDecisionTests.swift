import Testing
@testable import NerdzAppUpdates

@Suite("AppUpdateType decision")
struct AppUpdateTypeDecisionTests {
    @Test("Required version ahead of current is a hard update")
    func testWhenRequiredAheadShouldReturnHardUpdate() {
        let current = "1.0.0"
        let required = "2.0.0"
        let expected = AppUpdateType.hardUpdate
        let result = AppUpdateType(recommendedVersion: "1.0.0", requiredVersion: required, currentVersion: current)
        #expect(result == expected)
    }

    @Test("Recommended ahead of current, required not ahead, is a soft update")
    func testWhenRecommendedAheadShouldReturnSoftUpdate() {
        let current = "1.0.0"
        let recommended = "1.1.0"
        let expected = AppUpdateType.softUpdate
        let result = AppUpdateType(recommendedVersion: recommended, requiredVersion: "1.0.0", currentVersion: current)
        #expect(result == expected)
    }

    @Test("Neither ahead of current needs no update")
    func testWhenNeitherAheadShouldReturnNotNeeded() {
        let current = "2.0.0"
        let expected = AppUpdateType.notNeeded
        let result = AppUpdateType(recommendedVersion: "1.0.0", requiredVersion: "1.5.0", currentVersion: current)
        #expect(result == expected)
    }

    @Test("Missing current version needs no update")
    func testWhenCurrentVersionMissingShouldReturnNotNeeded() {
        let expected = AppUpdateType.notNeeded
        let result = AppUpdateType(recommendedVersion: "9.9.9", requiredVersion: "9.9.9", currentVersion: nil)
        #expect(result == expected)
    }
}
