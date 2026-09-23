import Testing
@testable import NerdzAppUpdates

@Suite("AppUpdateType")
struct AppUpdateTypeTests {
    @Test("Cases are equatable")
    func testWhenSameCaseShouldBeEqual() {
        let expected = AppUpdateType.hardUpdate
        #expect(expected == .hardUpdate)
        #expect(expected != .softUpdate)
    }
}
