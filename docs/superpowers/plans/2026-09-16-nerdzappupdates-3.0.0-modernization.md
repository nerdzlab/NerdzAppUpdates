# NerdzAppUpdates 3.0.0 Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship NerdzAppUpdates 3.0.0 with a Swift Testing suite at 80 percent or better, two bug fixes, a Swift 6 Sendable pass, an additive async API, DocC, CI, and lint config.

**Architecture:** Extract the pure version decision logic out of the UIKit and network coupled types into small internal seams so it can be unit tested without network or Firebase. Keep the completion handler API, add async variants on top. Make value types `Sendable` and `Equatable`, refine the provider protocol with `Sendable`, and isolate the UIKit driver with `@MainActor`.

**Tech Stack:** Swift 5.9 tools, iOS 15, Swift Testing, NerdzNetworking, NerdzUtils, Version (mrackwitz), Firebase RemoteConfig 12.x, DocC, GitHub Actions (macOS), SwiftLint, SwiftFormat.

**Spec:** `docs/superpowers/specs/2026-09-16-nerdzappupdates-3.0.0-modernization-design.md`

## Global Constraints

- VERIFICATION METHOD (overrides every `swift build` / `swift test` command written in the tasks below). This library imports UIKit and pulls FirebaseRemoteConfig, so it cannot build or test on the macOS host. All building and testing runs on an iOS Simulator via xcodebuild, wrapped in committed helper scripts:
  - Run the test suite: `bash scripts/test-ios.sh` (builds for testing on a generic iOS Simulator, then runs on iPhone 16 Pro). There is no `--filter`; the suite is small, run all of it.
  - Strict concurrency gate: `bash scripts/strict-concurrency.sh`.
  - Coverage (Task 13): `COVERAGE=1 bash scripts/test-ios.sh` then read the `.xcresult` with `xcrun xccov`.
  Wherever a task step says `swift test ...` or `swift build ...`, use the corresponding script instead.
- swift-tools-version 5.9. Do not raise or lower it.
- Platforms stay `platforms: [.iOS(.v15)]`. Do not add other platforms (UIKit plus Firebase preclude Linux and non iOS).
- Target version is 3.0.0. This is a breaking major release.
- Team skills are mandatory before writing the matching Swift: `/nerd-swift-testing` for tests, `/nerd-swift-docc` for DocC, `/nerd-swift-concurrency` for the Sendable and async pass, `/nerd-swift-networking` for App Store request or DTO work, `/nerd-swift-codestyle` and `/nerd-swift-architecture` for type placement, `/nerd-swift-code-review` for the final pass.
- Test rule: never type the same literal in both the arrange or act and the assert. Extract one local constant and reference it in both. Exception: asserting a type's built in default against a literal.
- Docs rule: no dash punctuation (no `—`, `–`, or ` - `) in README, CHANGELOG, or DocC. Use periods, commas, or parentheses.
- Conventional commits. Do not push and do not open a PR until asked.
- Integration branch is `release/3.0.0`. Each task lists its own working branch, merged into `release/3.0.0` with `--no-ff`.

## File Structure

New files:
- `Tests/NerdzAppUpdatesTests/` test suites (one file per unit under test).
- `Tests/NerdzAppUpdatesTests/TestHelpers/TestData.swift` factories.
- `Sources/NerdzAppUpdates/VersionProviders/AppStore/AppStoreVersionComparator.swift` pure comparator.
- `Sources/NerdzAppUpdates/General/CurrentAppVersionProviding.swift` current version seam.
- `Sources/NerdzAppUpdates/General/UpdateResolution.swift` pure result selection.
- `Sources/NerdzAppUpdates/Documentation.docc/NerdzAppUpdates.md` and `GettingStarted.md`.
- `.swiftlint.yml`, `.swiftformat`, `.github/workflows/ci.yml`.

Modified files:
- `Package.swift` (add test target).
- `AppUpdateType.swift`, `AppStoreVersionProvider.swift`, `FirebaseConfigVersionProvider.swift`, `VersionVerifier.swift`, `VersionProviderType.swift`, `VersionVerifierError.swift`, `Typealiases.swift`.
- `README.md`, `CHANGELOG.md`.

---

## Task 0: Create the integration branch

- [ ] **Step 1: Create and switch to the release branch**

```bash
cd /Users/roman/Documents/PersonalProjects/NerdzAppUpdates
git checkout master
git checkout -b release/3.0.0
```

- [ ] **Step 2: Confirm clean baseline builds**

```bash
swift build
```
Expected: build succeeds (Firebase resolves).

No commit. This branch only integrates the task branches below.

---

## Task 1: Test target and Equatable/Sendable on result value types

Branch: `test/foundation` off `release/3.0.0`.

Adds the Swift Testing target and makes the two result value types `Equatable` and `Sendable` so tests can assert on them. Invoke `/nerd-swift-testing` before writing tests and `/nerd-swift-concurrency` before touching the value types.

**Files:**
- Modify: `Package.swift`
- Modify: `Sources/NerdzAppUpdates/General/Models/Internal/AppUpdateType.swift`
- Modify: `Sources/NerdzAppUpdates/General/Models/Internal/VersionVerifierError.swift`
- Create: `Tests/NerdzAppUpdatesTests/AppUpdateTypeTests.swift`

**Interfaces:**
- Produces: `AppUpdateType: Equatable, Sendable`, `VersionVerifierError: Equatable, Sendable`. Later tasks assert on both.

- [ ] **Step 1: Add the test target to Package.swift**

Add after the `.target(...)` block, inside `targets:`:

```swift
        ,
        .testTarget(
            name: "NerdzAppUpdatesTests",
            dependencies: [
                "NerdzAppUpdates",
                .product(name: "Version", package: "Version")
            ]
        )
```

- [ ] **Step 2: Make the result types Equatable and Sendable**

In `VersionVerifierError.swift`, change the declaration line to:

```swift
public enum VersionVerifierError: Error, Equatable, Sendable {
```

In `AppUpdateType.swift`, change the declaration line to:

```swift
public enum AppUpdateType: Equatable, Sendable {
```

- [ ] **Step 3: Write a failing test for AppUpdateType equality**

Create `Tests/NerdzAppUpdatesTests/AppUpdateTypeTests.swift`:

```swift
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
```

- [ ] **Step 4: Run the suite and verify it passes**

Run: `swift test`
Expected: builds and passes. If the test target fails to resolve, fix the `Package.swift` comma placement.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "test: add Swift Testing target, make result types Equatable and Sendable"
```

---

## Task 2: Extract the App Store version comparator (pure) with tests

Branch: `test/appstore-comparator` off `release/3.0.0`.

The major or minor decision lives inside the `private` `handleGetAppInfoRequestSuccess`. Extract it into a pure static function so it is testable, then have the provider call it. Invoke `/nerd-swift-networking` and `/nerd-swift-testing`.

**Files:**
- Create: `Sources/NerdzAppUpdates/VersionProviders/AppStore/AppStoreVersionComparator.swift`
- Modify: `Sources/NerdzAppUpdates/VersionProviders/AppStore/AppStoreVersionProvider.swift:54-65`
- Create: `Tests/NerdzAppUpdatesTests/AppStoreVersionComparatorTests.swift`

**Interfaces:**
- Produces: `enum AppStoreVersionComparator { static func updateType(current: Version, store: Version) -> AppUpdateType }`.

- [ ] **Step 1: Write the failing test**

Create `Tests/NerdzAppUpdatesTests/AppStoreVersionComparatorTests.swift`:

```swift
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
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `swift test --filter AppStoreVersionComparator`
Expected: FAIL, `AppStoreVersionComparator` not found.

- [ ] **Step 3: Create the comparator**

Create `Sources/NerdzAppUpdates/VersionProviders/AppStore/AppStoreVersionComparator.swift`:

```swift
import Version

/// Pure comparison of the installed version against the App Store version.
enum AppStoreVersionComparator {

    /// Decides the update type from two semantic versions.
    /// A lower major triggers a hard update. A matching major with a lower minor triggers a soft update.
    /// - Parameters:
    ///   - current: The installed app version.
    ///   - store: The version reported by the App Store.
    /// - Returns: The resulting update type.
    static func updateType(current: Version, store: Version) -> AppUpdateType {
        if current.major < store.major {
            return .hardUpdate
        }

        if current.major == store.major, let minor = current.minor, let storeMinor = store.minor, minor < storeMinor {
            return .softUpdate
        }

        return .notNeeded
    }
}
```

- [ ] **Step 4: Route the provider through the comparator**

In `AppStoreVersionProvider.swift`, replace the `if currentAppVersion.major ...` block (lines 54-65) with:

```swift
        let updateType = AppStoreVersionComparator.updateType(current: currentAppVersion, store: appStoreVersion)
        completion(.success((updateType, appStoreAppInfo.version)))
```

- [ ] **Step 5: Run tests and build**

Run: `swift test --filter AppStoreVersionComparator`
Expected: PASS.
Run: `swift build`
Expected: succeeds.

- [ ] **Step 6: Commit**

```bash
git add Sources Tests
git commit -m "refactor: extract pure AppStoreVersionComparator with tests"
```

---

## Task 3: Inject the current app version seam into AppUpdateType

Branch: `test/current-version-seam` off `release/3.0.0`.

`AppUpdateType.init(recommendedVersion:requiredVersion:)` reads `Bundle.main.nz.appVersion` directly, which blocks testing the Firebase decision path. Add an internal initializer that accepts the current version, and keep the existing one delegating to `Bundle.main`. Invoke `/nerd-swift-testing`.

**Files:**
- Modify: `Sources/NerdzAppUpdates/General/Models/Internal/AppUpdateType.swift:22-37`
- Create: `Tests/NerdzAppUpdatesTests/AppUpdateTypeDecisionTests.swift`

**Interfaces:**
- Produces: `AppUpdateType.init(recommendedVersion: String?, requiredVersion: String?, currentVersion: String?)`. The Firebase provider and tests use it.

- [ ] **Step 1: Write the failing test**

Create `Tests/NerdzAppUpdatesTests/AppUpdateTypeDecisionTests.swift`:

```swift
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
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `swift test --filter "AppUpdateType decision"`
Expected: FAIL, no initializer with `currentVersion`.

- [ ] **Step 3: Add the injectable initializer**

In `AppUpdateType.swift`, replace the existing `init(recommendedVersion:requiredVersion:)` (lines 22-37) with:

```swift
    init(recommendedVersion: String?, requiredVersion: String?) {
        self.init(
            recommendedVersion: recommendedVersion,
            requiredVersion: requiredVersion,
            currentVersion: Bundle.main.nz.appVersion
        )
    }

    init(recommendedVersion: String?, requiredVersion: String?, currentVersion: String?) {
        guard let currentVersion else {
            self = .notNeeded
            return
        }

        if requiredVersion?.nz.isVersion(greaterThan: currentVersion) == true {
            self = .hardUpdate
        }
        else if recommendedVersion?.nz.isVersion(greaterThan: currentVersion) == true {
            self = .softUpdate
        }
        else {
            self = .notNeeded
        }
    }
```

- [ ] **Step 4: Run tests and build**

Run: `swift test --filter "AppUpdateType decision"`
Expected: PASS.
Run: `swift build`
Expected: succeeds.

- [ ] **Step 5: Commit**

```bash
git add Sources Tests
git commit -m "refactor: inject current app version into AppUpdateType for testability"
```

---

## Task 4: Fix the Firebase recommended key default (bug, test first)

Branch: `fix/firebase-recommended-key` off `release/3.0.0`.

`FirebaseConfigVersionProvider.init` defaults `recommendedKey` to `Constants.Keys.requiredVersion`, so the recommended (soft update) value is never read from Remote Config under the default initializer. This is a behavior change fix. Invoke `/nerd-swift-testing`.

**Files:**
- Modify: `Sources/NerdzAppUpdates/VersionProviders/Firebase/FirebaseConfigVersionProvider.swift:25`
- Create: `Tests/NerdzAppUpdatesTests/FirebaseConfigVersionProviderTests.swift`

**Interfaces:**
- Consumes: `FirebaseConfigVersionProvider.Constants.Keys.recommendedVersion` and `.requiredVersion` (both already `public static let`).

- [ ] **Step 1: Write the failing test asserting the default keys differ**

Create `Tests/NerdzAppUpdatesTests/FirebaseConfigVersionProviderTests.swift`:

```swift
import Testing
@testable import NerdzAppUpdates

@Suite("FirebaseConfigVersionProvider")
struct FirebaseConfigVersionProviderTests {

    @Test("Default recommended and required keys are distinct")
    func testWhenUsingDefaultKeysShouldBeDistinct() {
        let recommended = FirebaseConfigVersionProvider.Constants.Keys.recommendedVersion
        let required = FirebaseConfigVersionProvider.Constants.Keys.requiredVersion
        let provider = FirebaseConfigVersionProvider()
        #expect(provider.recommendedKey == recommended)
        #expect(provider.requiredKey == required)
        #expect(provider.recommendedKey != provider.requiredKey)
    }
}
```

Note: this test reads `recommendedKey` and `requiredKey`. Change their access from `private let` to `let` with `internal` visibility in the same file so `@testable import` can read them (they are not part of the public API).

- [ ] **Step 2: Expose the stored keys to the test target**

In `FirebaseConfigVersionProvider.swift`, change:

```swift
    private let config: RemoteConfig
    private let recommendedKey: String
    private let requiredKey: String
```
to:

```swift
    private let config: RemoteConfig
    let recommendedKey: String
    let requiredKey: String
```

- [ ] **Step 3: Run it to confirm it fails**

Run: `swift test --filter FirebaseConfigVersionProvider`
Expected: FAIL, `recommendedKey` equals `requiredVersion`.

- [ ] **Step 4: Fix the default**

In `FirebaseConfigVersionProvider.swift` line 25, change the init signature default:

```swift
    public init(config: RemoteConfig = .remoteConfig(), recommendedKey: String = Constants.Keys.recommendedVersion, requiredKey: String = Constants.Keys.requiredVersion) {
```

- [ ] **Step 5: Run tests**

Run: `swift test --filter FirebaseConfigVersionProvider`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources Tests
git commit -m "fix: read recommendedVersion key by default in FirebaseConfigVersionProvider"
```

---

## Task 5: Fix the data race in verifyVersion (bug, test first)

Branch: `fix/verify-version-data-race` off `release/3.0.0`.

`verifyVersion` appends to a shared `results` array from each provider completion with no synchronization. Extract the result selection into a pure function first (so aggregation is testable), then fix the collection to be race free. Invoke `/nerd-swift-concurrency` and `/nerd-swift-testing`.

**Files:**
- Create: `Sources/NerdzAppUpdates/General/UpdateResolution.swift`
- Modify: `Sources/NerdzAppUpdates/General/VersionVerifier.swift:39-100,176-198`
- Create: `Tests/NerdzAppUpdatesTests/UpdateResolutionTests.swift`
- Create: `Tests/NerdzAppUpdatesTests/TestHelpers/TestData.swift`

**Interfaces:**
- Produces: `enum UpdateResolution { static func selected(from results: [Result<VersionProviderResult, VersionVerifierError>]) -> (chosen: Result<VersionProviderResult, VersionVerifierError>?, presentation: UpdatePresentation) }` where `enum UpdatePresentation: Equatable { case hardUpdate(latestVersion: String?), softUpdate(latestVersion: String?), none }`.

- [ ] **Step 1: Write TestData factory**

Create `Tests/NerdzAppUpdatesTests/TestHelpers/TestData.swift`:

```swift
@testable import NerdzAppUpdates

enum TestData {
    static func success(_ type: AppUpdateType, _ version: String?) -> Result<VersionProviderResult, VersionVerifierError> {
        .success((type, version))
    }

    static func failure(_ error: VersionVerifierError) -> Result<VersionProviderResult, VersionVerifierError> {
        .failure(error)
    }
}
```

- [ ] **Step 2: Write the failing resolution tests**

Create `Tests/NerdzAppUpdatesTests/UpdateResolutionTests.swift`:

```swift
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
```

- [ ] **Step 3: Run it to confirm it fails**

Run: `swift test --filter UpdateResolution`
Expected: FAIL, `UpdateResolution` not found.

- [ ] **Step 4: Create UpdateResolution**

Create `Sources/NerdzAppUpdates/General/UpdateResolution.swift`:

```swift
/// What the verifier should present after aggregating provider results.
enum UpdatePresentation: Equatable {
    case hardUpdate(latestVersion: String?)
    case softUpdate(latestVersion: String?)
    case none
}

/// Pure selection of the winning result across providers.
/// A hard update takes precedence over a soft update, which takes precedence over no update.
enum UpdateResolution {
    static func selected(
        from results: [Result<VersionProviderResult, VersionVerifierError>]
    ) -> (chosen: Result<VersionProviderResult, VersionVerifierError>?, presentation: UpdatePresentation) {

        var softUpdate: (result: Result<VersionProviderResult, VersionVerifierError>, version: String?)?

        for result in results {
            guard case .success(let checkResult) = result else {
                continue
            }

            switch checkResult.type {
            case .hardUpdate:
                return (result, .hardUpdate(latestVersion: checkResult.latestVersion))

            case .softUpdate where softUpdate == nil:
                softUpdate = (result, checkResult.latestVersion)

            default:
                continue
            }
        }

        if let softUpdate {
            return (softUpdate.result, .softUpdate(latestVersion: softUpdate.version))
        }

        return (results.first, .none)
    }
}
```

- [ ] **Step 5: Run resolution tests**

Run: `swift test --filter UpdateResolution`
Expected: PASS.

- [ ] **Step 6: Rewrite verifyVersion to use race free collection and the resolver**

In `VersionVerifier.swift`, replace the body of `verifyVersion(completion:)` (lines 176-198) with a fixed size buffer filled by index, then delegate presentation:

```swift
    public func verifyVersion(completion: @escaping AppUpdateAction) {
        startLoading()

        let providers = versionDataProviders
        var results = [Result<VersionProviderResult, VersionVerifierError>?](repeating: nil, count: providers.count)
        let dispatchGroup = DispatchGroup()

        for (index, provider) in providers.enumerated() {
            dispatchGroup.enter()
            provider.verifyAppVersion { result in
                results[index] = result
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.stopLoading()

            let collected = results.compactMap { $0 }
            let outcome = UpdateResolution.selected(from: collected)
            self?.present(outcome.presentation)
            completion(outcome.chosen ?? .failure(.unknownError))
        }
    }
```

Writing each provider's result to its own preassigned index removes the shared append. Each index is written exactly once by exactly one callback.

- [ ] **Step 7: Replace handleDataProviderVersionVerification with a present method**

In `VersionVerifier.swift`, replace `handleDataProviderVersionVerification(with:)` (lines 39-100) with a presentation only method that consumes `UpdatePresentation`:

```swift
    private func present(_ presentation: UpdatePresentation) {
        switch presentation {
        case .hardUpdate(let latestVersion):
            guard let hardUpdateMode else {
                return
            }
            switch hardUpdateMode {
            case .screen(let screen):
                screen.latestVersion = latestVersion
                showScreenForHardUpdate(screen)
            case .custom(let action):
                action(latestVersion)
            }

        case .softUpdate(let latestVersion):
            guard let softUpdateMode else {
                return
            }
            switch softUpdateMode {
            case .screen(let screen, let animated):
                screen.latestVersion = latestVersion
                showScreenForSoftUpdate(screen, animated: animated)
            case .alert(let alert):
                show(alert)
            case .custom(let action):
                action(latestVersion)
            }

        case .none:
            break
        }
    }
```

- [ ] **Step 8: Run the whole suite and build**

Run: `swift test`
Expected: PASS.
Run: `swift build`
Expected: succeeds.

- [ ] **Step 9: Commit**

```bash
git add Sources Tests
git commit -m "fix: remove data race in verifyVersion, extract pure UpdateResolution"
```

---

## Task 6: Remove dead code

Branch: `chore/remove-dead-code` off `release/3.0.0`.

`VersionVerifierError.osIsNoLongerSupported` is declared and never thrown.

**Files:**
- Modify: `Sources/NerdzAppUpdates/General/Models/Internal/VersionVerifierError.swift:17`

- [ ] **Step 1: Confirm it is unused**

Run: `grep -rn "osIsNoLongerSupported" Sources Tests`
Expected: only the declaration line.

- [ ] **Step 2: Remove the case**

In `VersionVerifierError.swift`, delete the line `    case osIsNoLongerSupported`.

- [ ] **Step 3: Build and test**

Run: `swift build && swift test`
Expected: succeeds and passes.

- [ ] **Step 4: Commit**

```bash
git add Sources
git commit -m "chore: remove unused osIsNoLongerSupported error case"
```

---

## Task 7: Swift 6 Sendable pass and UIKit isolation

Branch: `feature/sendable-swift6` off `release/3.0.0`.

Make the library clean under complete strict concurrency. Invoke `/nerd-swift-concurrency` before starting.

**Files:**
- Modify: `Typealiases.swift`, `VersionProviderType.swift`, `VersionVerifier.swift`, `AppStoreVersionProvider.swift`, `FirebaseConfigVersionProvider.swift`

**Interfaces:**
- Produces: `VersionProviderType: NSObjectProtocol, Sendable`; `@Sendable` closure typealiases; `@MainActor final class VersionVerifier`.

- [ ] **Step 1: Establish the baseline failure**

Run: `bash scripts/strict-concurrency.sh`
Expected: it reports concurrency warnings in Sources (non-clean). Record them.

- [ ] **Step 2: Mark closure typealiases @Sendable**

In `Typealiases.swift`, change to:

```swift
public typealias VersionVerifierEmptyAction = @Sendable () -> Void
public typealias VersionProviderResult = (type: AppUpdateType, latestVersion: String?)
public typealias AppUpdateAction = @Sendable (Result<VersionProviderResult, VersionVerifierError>) -> Void
public typealias VersionVerifierStringAction = @Sendable (String?) -> Void
```

- [ ] **Step 3: Refine the provider protocol with Sendable**

In `VersionProviderType.swift`, change to:

```swift
public protocol VersionProviderType: NSObjectProtocol, Sendable {
    func verifyAppVersion(completion: @escaping AppUpdateAction)
}
```

- [ ] **Step 4: Make providers final and Sendable safe**

In `AppStoreVersionProvider.swift`, change `public class AppStoreVersionProvider` to `public final class AppStoreVersionProvider`, and make mutable state safe: change `public var country: AppStoreCountry` to `public let country: AppStoreCountry` (a provider's country should not change after init). If a setter is required by consumers, keep `var` and mark the class `@unchecked Sendable` with a documented invariant instead.

In `FirebaseConfigVersionProvider.swift`, change `public class` to `public final class`. `RemoteConfig` is a Firebase reference type; annotate the class `@unchecked Sendable` with a comment that its stored properties are immutable and `RemoteConfig` is used only inside its own callback.

- [ ] **Step 5: Isolate VersionVerifier to the main actor**

In `VersionVerifier.swift`, change `public class VersionVerifier` to `@MainActor public final class VersionVerifier`. Replace the deprecated key window lookup in `showScreenForHardUpdate` and `show(_:)`:

```swift
    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
```

Then use `keyWindow` in place of `UIApplication.shared.windows.filter { $0.isKeyWindow }.first`.

- [ ] **Step 6: Replace print with Logger**

At the top of `VersionVerifier.swift` add `import os`, declare `private static let logger = Logger(subsystem: "NerdzAppUpdates", category: "VersionVerifier")`, and replace `print("Version check error, overlay dissmiss")` with `Self.logger.error("Failed to dismiss soft update overlay")`.

- [ ] **Step 7: Build strict concurrency clean**

Run: `bash scripts/strict-concurrency.sh`
Expected: `strict-concurrency clean`. If the `results` buffer in `verifyVersion` warns about capture, hoist it into a small `@unchecked Sendable` lock guarded box or fill it via a `TaskGroup`. Document the chosen fix inline.

- [ ] **Step 8: Run tests**

Run: `bash scripts/test-ios.sh`
Expected: PASS. If `@MainActor` isolation breaks a test, annotate that test `@MainActor`.

- [ ] **Step 9: Commit**

```bash
git add Sources Tests
git commit -m "feat!: Swift 6 Sendable pass, main actor isolation, os.Logger"
```

---

## Task 8: Additive async API

Branch: `feature/async-api` off `release/3.0.0`.

Add async variants that bridge to the completion methods. The protocol requirement carries a default implementation so existing conformers keep compiling. Invoke `/nerd-swift-concurrency`.

**Files:**
- Modify: `Sources/NerdzAppUpdates/VersionProviders/VersionProviderType.swift`
- Modify: `Sources/NerdzAppUpdates/General/VersionVerifier.swift`
- Create: `Tests/NerdzAppUpdatesTests/AsyncBridgingTests.swift`

**Interfaces:**
- Produces: `VersionProviderType.verifyAppVersion() async -> Result<VersionProviderResult, VersionVerifierError>` (default bridges to completion), and `VersionVerifier.verifyVersion() async -> Result<VersionProviderResult, VersionVerifierError>`.

- [ ] **Step 1: Write a failing test with a stub provider**

Create `Tests/NerdzAppUpdatesTests/AsyncBridgingTests.swift`:

```swift
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
        #expect(result == .success((.softUpdate, latest)))
    }
}
```

Note: `VersionProviderResult` is a tuple, which is not `Equatable` by default. Add `func == ` support by comparing fields in the test, or assert on the unwrapped components. Concretely, replace the final `#expect` with:

```swift
        guard case .success(let value) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(value.type == .softUpdate)
        #expect(value.latestVersion == latest)
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `swift test --filter "Async bridging"`
Expected: FAIL, no async `verifyAppVersion()`.

- [ ] **Step 3: Add the async protocol requirement with a default bridge**

In `VersionProviderType.swift`, add the async requirement and a default extension:

```swift
public protocol VersionProviderType: NSObjectProtocol, Sendable {
    func verifyAppVersion(completion: @escaping AppUpdateAction)
    func verifyAppVersion() async -> Result<VersionProviderResult, VersionVerifierError>
}

public extension VersionProviderType {
    func verifyAppVersion() async -> Result<VersionProviderResult, VersionVerifierError> {
        await withCheckedContinuation { continuation in
            verifyAppVersion { result in
                continuation.resume(returning: result)
            }
        }
    }
}
```

- [ ] **Step 4: Add the async verifier entry point**

In `VersionVerifier.swift`, add:

```swift
    /// Async variant of ``verifyVersion(completion:)``. Presentation still happens on the main actor.
    /// - Returns: The selected provider result, or a failure if none was produced.
    public func verifyVersion() async -> Result<VersionProviderResult, VersionVerifierError> {
        await withCheckedContinuation { continuation in
            verifyVersion { result in
                continuation.resume(returning: result)
            }
        }
    }
```

- [ ] **Step 5: Run tests and strict concurrency build**

Run: `swift test`
Expected: PASS.
Run: `swift build -Xswiftc -strict-concurrency=complete 2>&1 | grep warning || echo "clean"`
Expected: `clean`.

- [ ] **Step 6: Commit**

```bash
git add Sources Tests
git commit -m "feat: add async verifyVersion and verifyAppVersion bridging APIs"
```

---

## Task 9: DocC catalog and doc comments

Branch: `docs/docc` off `release/3.0.0`.

Invoke `/nerd-swift-docc` before writing. No dash punctuation.

**Files:**
- Create: `Sources/NerdzAppUpdates/Documentation.docc/NerdzAppUpdates.md`
- Create: `Sources/NerdzAppUpdates/Documentation.docc/GettingStarted.md`
- Modify: public symbol files to add or fix `///` comments and typos (`dissmiss`, `retreiving`, `sciped`).

- [ ] **Step 1: Create the landing page**

Create `Sources/NerdzAppUpdates/Documentation.docc/NerdzAppUpdates.md`:

```markdown
# ``NerdzAppUpdates``

Check whether the installed app version is up to date and prompt for soft or hard updates.

## Overview

NerdzAppUpdates verifies the installed version against a distribution service using one or more providers, then presents a soft update (skippable) or a hard update (blocking).

## Topics

### Essentials

- <doc:GettingStarted>
- ``VersionVerifier``
- ``VersionProviderType``

### Providers

- ``AppStoreVersionProvider``
- ``FirebaseConfigVersionProvider``

### Models

- ``AppUpdateType``
- ``VersionVerifierError``
```

- [ ] **Step 2: Create the Getting Started article**

Create `Sources/NerdzAppUpdates/Documentation.docc/GettingStarted.md` with a compiling App Store example (mirror the README usage, no dash punctuation).

- [ ] **Step 3: Add doc comments to every public symbol**

Add `///` summaries (plus parameters, returns, throws where relevant) to every public declaration lacking one, and fix the typos in existing comments. Verify the public surface:

```bash
grep -rn "public " Sources | grep -v "///"
```

- [ ] **Step 4: Build DocC clean**

Run:
```bash
xcodebuild docbuild -scheme NerdzAppUpdates -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath .build/docc 2>&1 | grep -iE '(warning|error): ' | grep -v 'multiple matching' || echo "DocC clean"
```
Expected: `DocC clean`.

- [ ] **Step 5: Commit**

```bash
git add Sources
git commit -m "docs: add DocC catalog and doc comments to public API"
```

---

## Task 10: README and CHANGELOG for 3.0.0

Branch: `docs/readme-changelog` off `release/3.0.0`.

No dash punctuation.

**Files:**
- Modify: `README.md`, `CHANGELOG.md`

- [ ] **Step 1: Update README**

Add an async usage example alongside the completion example. Update requirements to Swift 5.9, iOS 15, and note 3.0.0 breaking changes (the `VersionProviderType` Sendable requirement, the `@MainActor` isolation of `VersionVerifier`, and the Firebase key default fix). Keep every snippet compiling against the current API.

- [ ] **Step 2: Add the 3.0.0 CHANGELOG section**

Prepend a `## [3.0.0]` section in Keep a Changelog format with a one line breaking summary, then Added (async API, tests, DocC, CI, lint), Changed (`VersionProviderType` now `Sendable`, `VersionVerifier` now `@MainActor` and `final`, providers `final`), Removed (`osIsNoLongerSupported`), Fixed (data race in `verifyVersion`), and a Behavior change note (Firebase now reads `recommendedVersion` by default).

- [ ] **Step 3: Verify no dash punctuation**

Run: `grep -nE '—|–| - [a-z]|[a-z] - ' README.md CHANGELOG.md || echo "clean"`
Expected: `clean`.

- [ ] **Step 4: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: update README and CHANGELOG for 3.0.0"
```

---

## Task 11: Lint and format config

Branch: `chore/lint-config` off `release/3.0.0`.

Invoke `/nerd-swift-codestyle` for the rule set.

**Files:**
- Create: `.swiftlint.yml`, `.swiftformat`

- [ ] **Step 1: Add SwiftLint config**

Create `.swiftlint.yml` matching team defaults, scoped to `Sources` and `Tests`.

- [ ] **Step 2: Add SwiftFormat config**

Create `.swiftformat` matching team defaults.

- [ ] **Step 3: Run both if installed**

Run: `swiftlint --strict || true` and `swiftformat --lint . || true`
Fix any violations introduced by earlier tasks.

- [ ] **Step 4: Commit**

```bash
git add .swiftlint.yml .swiftformat Sources Tests
git commit -m "chore: add SwiftLint and SwiftFormat config"
```

---

## Task 12: CI on macOS

Branch: `ci/github-actions` off `release/3.0.0`.

Linux is not possible (UIKit plus Firebase), so CI runs on macOS.

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Add the workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [master]
  pull_request:
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Show Xcode version
        run: xcodebuild -version
      - name: Test on iOS Simulator
        run: bash scripts/test-ios.sh
      - name: Strict concurrency
        run: bash scripts/strict-concurrency.sh
```

Pick a `SIM_NAME` that exists on the runner image (the script defaults to iPhone 16 Pro). If the default runner Xcode lacks that simulator, set `SIM_NAME` via `env:` to one listed by `xcrun simctl list devices available` on the runner, or add a step that selects Xcode with `sudo xcode-select -s`.

- [ ] **Step 2: Validate YAML locally**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo ok`
Expected: `ok`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add macOS GitHub Actions workflow"
```

---

## Task 13: Integrate and run the verification gate

Branch: work on `release/3.0.0`.

- [ ] **Step 1: Merge each task branch with --no-ff in order**

```bash
git checkout release/3.0.0
git merge --no-ff test/foundation
git merge --no-ff test/appstore-comparator
git merge --no-ff test/current-version-seam
git merge --no-ff fix/firebase-recommended-key
git merge --no-ff fix/verify-version-data-race
git merge --no-ff chore/remove-dead-code
git merge --no-ff feature/sendable-swift6
git merge --no-ff feature/async-api
git merge --no-ff docs/docc
git merge --no-ff docs/readme-changelog
git merge --no-ff chore/lint-config
git merge --no-ff ci/github-actions
```
Resolve conflicts as they arise (the VersionVerifier and provider files are touched by several tasks).

- [ ] **Step 2: Run the full verification gate**

```bash
bash scripts/strict-concurrency.sh
COVERAGE=1 bash scripts/test-ios.sh
# Coverage for Sources only, from the .xcresult produced under .build/dd:
XCRESULT=$(find .build/dd/Logs/Test -name '*.xcresult' | head -1)
xcrun xccov view --report "$XCRESULT" | grep -iE 'NerdzAppUpdates|Sources'
```
Expected: strict-concurrency clean, tests pass, coverage 80 percent or better on Sources.

- [ ] **Step 3: Final review**

Invoke `/nerd-swift-code-review` over the diff `git diff master...release/3.0.0`. Address critical and high findings. Confirm the docs gate: `grep -nE '—|–| - [a-z]|[a-z] - ' README.md CHANGELOG.md Sources/NerdzAppUpdates/Documentation.docc/*.md || echo clean`.

- [ ] **Step 4: Stop**

Do not push or open a PR or tag. Report status and wait for instruction.

---

## Self-Review notes

- Spec coverage: tests (Tasks 1-8), Firebase key bug (Task 4), data race (Task 5), dead code (Task 6), Sendable pass (Task 7), async API (Task 8), DocC (Task 9), README and CHANGELOG (Task 10), lint (Task 11), CI (Task 12), verification gate (Task 13). All spec sections map to a task.
- Type consistency: `AppStoreVersionComparator.updateType(current:store:)`, `AppUpdateType.init(recommendedVersion:requiredVersion:currentVersion:)`, `UpdateResolution.selected(from:)`, `UpdatePresentation`, and the async signatures are referenced consistently across tasks.
- Known risk to watch during execution: the exact NerdzUtils API names (`Bundle.main.nz.appVersion`, `String.nz.isVersion(greaterThan:)`) and the `Version` initializer are taken from existing source. If a name differs, match the existing call sites, do not invent.
- Coverage risk: the UIKit presentation methods in `VersionVerifier` are not unit tested. The extraction of `UpdateResolution` moves the decision logic out of the UIKit path, which is what carries most of the testable lines. If Sources coverage lands under 80 percent, add tests for `AppStoreCountry` codes and `AppUpdateType` edge cases before adding UIKit test scaffolding.
