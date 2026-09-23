import Foundation
import Testing
@testable import NerdzAppUpdates

private final class StubProvider: NSObject, VersionProviderType, @unchecked Sendable {
    let stubbed: Result<VersionProviderResult, VersionVerifierError>
    init(stubbed: Result<VersionProviderResult, VersionVerifierError>) {
        self.stubbed = stubbed
    }

    func verifyAppVersion(completion: @escaping AppUpdateAction) {
        completion(stubbed)
    }
}

@Suite("Async bridging")
struct AsyncBridgingTests {
    @Test("Default async provider bridges to the completion result")
    func testWhenProviderReturnsSoftUpdateShouldBridgeToAsync() async {
        let latest = "2.5.0"
        let provider = StubProvider(stubbed: .success((.softUpdate, latest)))
        let result = await provider.verifyAppVersion()
        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .softUpdate)
        #expect(value.latestVersion == latest)
    }
}
