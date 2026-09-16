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

/// Lock-guarded recorder for values produced by `@Sendable` closures (such as the `.custom`
/// mode actions), which cannot capture a mutable `var` local directly.
private final class Recorder<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [T] = []

    var values: [T] {
        lock.lock()
        defer { lock.unlock() }
        return _values
    }

    func record(_ value: T) {
        lock.lock()
        _values.append(value)
        lock.unlock()
    }
}

@MainActor
@Suite("VersionVerifier")
struct VersionVerifierTests {
    @Test("A hard update fires the hard custom action and resolves to hardUpdate")
    func testWhenHardUpdateShouldFireHardActionAndResolve() async {
        let latest = "4.0.0"
        let provider = StubProvider(stubbed: TestData.success(.hardUpdate, latest))
        let hardRecorder = Recorder<String?>()
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            hardUpdateMode: .custom { hardRecorder.record($0) }
        )

        let result = await verifier.verifyVersion()

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .hardUpdate)
        #expect(value.latestVersion == latest)
        #expect(hardRecorder.values == [latest])
    }

    @Test("A soft update fires the soft custom action and resolves to softUpdate")
    func testWhenSoftUpdateShouldFireSoftActionAndResolve() async {
        let latest = "2.5.0"
        let provider = StubProvider(stubbed: TestData.success(.softUpdate, latest))
        let softRecorder = Recorder<String?>()
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            softUpdateMode: .custom { softRecorder.record($0) }
        )

        let result = await verifier.verifyVersion()

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .softUpdate)
        #expect(value.latestVersion == latest)
        #expect(softRecorder.values == [latest])
    }

    @Test("No update needed fires neither custom action and resolves to notNeeded")
    func testWhenNotNeededShouldFireNeitherActionAndResolve() async {
        let provider = StubProvider(stubbed: TestData.success(.notNeeded, nil))
        let hardRecorder = Recorder<String?>()
        let softRecorder = Recorder<String?>()
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            softUpdateMode: .custom { softRecorder.record($0) },
            hardUpdateMode: .custom { hardRecorder.record($0) }
        )

        let result = await verifier.verifyVersion()

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .notNeeded)
        #expect(hardRecorder.values.isEmpty)
        #expect(softRecorder.values.isEmpty)
    }

    @Test("A hard update takes precedence over a soft update when both are configured")
    func testWhenHardAndSoftBothConfiguredShouldOnlyFireHardAction() async {
        let softLatest = "2.5.0"
        let hardLatest = "4.0.0"
        let softProvider = StubProvider(stubbed: TestData.success(.softUpdate, softLatest))
        let hardProvider = StubProvider(stubbed: TestData.success(.hardUpdate, hardLatest))
        let hardRecorder = Recorder<String?>()
        let softRecorder = Recorder<String?>()
        let verifier = VersionVerifier(
            versionDataProvider: softProvider,
            hardProvider,
            softUpdateMode: .custom { softRecorder.record($0) },
            hardUpdateMode: .custom { hardRecorder.record($0) }
        )

        let result = await verifier.verifyVersion()

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .hardUpdate)
        #expect(hardRecorder.values == [hardLatest])
        #expect(softRecorder.values.isEmpty)
    }

    @Test("A hard update with only a soft mode configured does not fire the soft action")
    func testWhenHardUpdateWithOnlySoftModeConfiguredShouldNotFireSoftAction() async {
        let latest = "4.0.0"
        let provider = StubProvider(stubbed: TestData.success(.hardUpdate, latest))
        let softRecorder = Recorder<String?>()
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            softUpdateMode: .custom { softRecorder.record($0) }
        )

        let result = await verifier.verifyVersion()

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .hardUpdate)
        #expect(softRecorder.values.isEmpty)
    }

    @Test("A custom loading indication mode fires both start and stop")
    func testWhenCustomLoadingIndicationShouldFireStartAndStop() async {
        let provider = StubProvider(stubbed: TestData.success(.notNeeded, nil))
        let startRecorder = Recorder<Void>()
        let stopRecorder = Recorder<Void>()
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            loadingIndicationMode: .custom({ startRecorder.record(()) }, { stopRecorder.record(()) })
        )

        _ = await verifier.verifyVersion()

        #expect(startRecorder.values.count == 1)
        #expect(stopRecorder.values.count == 1)
    }

    @Test("A none loading indication mode still completes with a result")
    func testWhenLoadingIndicationNoneShouldStillCompleteWithResult() async {
        let provider = StubProvider(stubbed: TestData.success(.notNeeded, nil))
        let verifier = VersionVerifier(versionDataProvider: provider)

        let result = await verifier.verifyVersion()

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .notNeeded)
    }

    @Test("The completion based API resolves with the same result as the async API")
    func testWhenUsingCompletionAPIShouldResolveWithExpectedResult() async {
        let latest = "4.0.0"
        let provider = StubProvider(stubbed: TestData.success(.hardUpdate, latest))
        let hardRecorder = Recorder<String?>()
        let verifier = VersionVerifier(
            versionDataProvider: provider,
            hardUpdateMode: .custom { hardRecorder.record($0) }
        )

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<VersionProviderResult, VersionVerifierError>, Never>) in
            verifier.verifyVersion { result in
                continuation.resume(returning: result)
            }
        }

        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .hardUpdate)
        #expect(hardRecorder.values == [latest])
    }

    @Test("All providers failing resolves to a failure result")
    func testWhenAllProvidersFailShouldResolveToFailure() async {
        let error = VersionVerifierError.unknownError
        let provider = StubProvider(stubbed: TestData.failure(error))
        let verifier = VersionVerifier(versionDataProvider: provider)

        let result = await verifier.verifyVersion()

        guard case .failure(let receivedError) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(receivedError == error)
    }
}
