import Testing
import Version
@testable import NerdzAppUpdates

@Suite("AppStoreVersionComparator")
struct AppStoreVersionComparatorTests {
    @Test("Lower major than store is a hard update")
    func testWhenMajorBehindShouldReturnHardUpdate() throws {
        let current = try Version("1.4.0")
        let store = try Version("2.0.0")
        let expected = AppUpdateType.hardUpdate
        #expect(AppStoreVersionComparator.updateType(current: current, store: store) == expected)
    }

    @Test("Same major, lower minor is a soft update")
    func testWhenMinorBehindShouldReturnSoftUpdate() throws {
        let current = try Version("2.1.0")
        let store = try Version("2.3.0")
        let expected = AppUpdateType.softUpdate
        #expect(AppStoreVersionComparator.updateType(current: current, store: store) == expected)
    }

    @Test("Equal versions need no update")
    func testWhenVersionsEqualShouldReturnNotNeeded() throws {
        let version = try Version("2.3.0")
        let expected = AppUpdateType.notNeeded
        #expect(AppStoreVersionComparator.updateType(current: version, store: version) == expected)
    }

    @Test("Ahead of store needs no update")
    func testWhenAheadOfStoreShouldReturnNotNeeded() throws {
        let current = try Version("2.4.0")
        let store = try Version("2.3.0")
        let expected = AppUpdateType.notNeeded
        #expect(AppStoreVersionComparator.updateType(current: current, store: store) == expected)
    }

    @Test("A current version with no minor component needs no update, even behind on minor")
    func testWhenCurrentMinorNilShouldReturnNotNeeded() throws {
        let current = try Version("2")
        let store = try Version("2.3.0")
        let expected = AppUpdateType.notNeeded
        #expect(current.minor == nil)
        #expect(AppStoreVersionComparator.updateType(current: current, store: store) == expected)
    }
}
