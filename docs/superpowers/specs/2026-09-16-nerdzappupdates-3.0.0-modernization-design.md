# NerdzAppUpdates 3.0.0 Modernization Design

Date: 2026-09-16

## Goal

Bring NerdzAppUpdates up to current standards following the Swift Library Modernization Playbook. Add real test coverage, DocC, CI, and lint config. Fix two correctness bugs. Complete a Swift 6 Sendable pass. Add an async/await API alongside the existing completion handler API. Ship as a breaking major release, 3.0.0.

## Confirmed decisions

1. Full scope, breaking release 3.0.0 (additive work plus the breaking Sendable pass).
2. Add async/await API alongside the existing completion handler API. The new async protocol requirement gets a default implementation that bridges to the completion method, so existing conformers keep compiling.
3. Swift Testing framework, target 80 percent coverage or better on Sources.

## Team skills to invoke during implementation

Per team convention, invoke the relevant nerd skill before writing the corresponding Swift, because these skills carry conventions that override generic Swift practice.

* Tests: invoke `/nerd-swift-testing` (struct based `@Suite`, `testWhen[Condition]Should[Expected]` naming, `private enum TestData` factories, Sourcery mocks, AAA).
* DocC: invoke `/nerd-swift-docc` (comment syntax, catalog layout, build and export conventions).
* Sendable and async pass: invoke `/nerd-swift-concurrency`.
* Networking touch points (App Store provider, request or DTO mapping): invoke `/nerd-swift-networking`.
* Any type, naming, or file organization work: invoke `/nerd-swift-codestyle`, and `/nerd-swift-architecture` for layer placement.
* Final review pass: invoke `/nerd-swift-code-review`.

## Current state (audited)

Already done in 2.0.0: swift tools 5.9, Firebase 12.x, iOS 15, README rewrite, CHANGELOG, branch cleanup with archive tags, clean semver major.

Gaps this release closes:

* No test target, zero coverage (17 source files, 208 public declarations). Tests will be written under `/nerd-swift-testing` conventions.
* Data race in `VersionVerifier.verifyVersion`. The `results` array is appended from multiple provider callbacks with no synchronization.
* Firebase key default bug. `FirebaseConfigVersionProvider.init` defaults `recommendedKey` to `Constants.Keys.requiredVersion`, so the recommended (soft update) signal is never read from Remote Config with the default initializer.
* No Sendable anywhere. Non final public classes, non Sendable protocol, closure typealiases not `@Sendable`, no `@MainActor` on the UIKit driving type.
* Deprecated `UIApplication.shared.windows` usage (deprecated since iOS 15).
* `print()` used for error reporting.
* Dead code, `VersionVerifierError.osIsNoLongerSupported` (declared, never thrown).
* No DocC catalog, uneven doc comments, typos (`dissmiss`, `retreiving`).
* No CI, no SwiftLint, no SwiftFormat config.

Platform note. Unlike the playbook default, this library imports UIKit and pulls Firebase, so it genuinely cannot build on Linux. Keep `platforms: [.iOS(.v15)]`. CI runs on macOS, not Ubuntu.

## Branch strategy

`release/3.0.0` is the integration branch. Each concern on its own branch, merged with `--no-ff`:

* `test/foundation` (test target plus first coverage of current behavior)
* `fix/firebase-recommended-key` (regression test then fix)
* `fix/verify-version-data-race` (regression test then fix)
* `chore/remove-dead-code`
* `feature/sendable-swift6`
* `feature/async-api`
* `docs/docc`
* `docs/readme-changelog`
* `ci/github-actions`
* `chore/lint-config`

No pushing and no PR until asked. Conventional commit messages (feat, fix, refactor, docs, test, chore, ci).

## Testability seams (core design)

The version decision logic is buried in private methods that read `Bundle.main` and call live networking, which blocks unit testing. Introduce minimal internal seams so the pure logic is testable without network or Firebase.

1. Extract a pure App Store comparator. A function taking `(current: Version, store: Version) -> AppUpdateType` that encodes the existing major and minor rules from `handleGetAppInfoRequestSuccess`. Unit tested directly.
2. Inject the current app version. `AppUpdateType.init(recommendedVersion:requiredVersion:)` and the App Store provider read `Bundle.main.nz.appVersion` internally. Add an internal current version seam (default reads `Bundle.main`) so tests feed a known version. Internal only, not a public API change.
3. App Store networking. Do not mock the NerdzNetworking `.execute().onSuccess` DSL. Test the comparator and the mapping from a decoded `AppStoreResponseApiModel`.
4. Firebase. `RemoteConfig` is already injectable via `init(config:)`. Wrap the key reading and `AppUpdateType` construction in a testable function. The key default regression test lives here.

Trade off. This adds a small comparator and a current version provider (both internal). This is the minimum refactor that makes the library honestly testable. Mocking the whole network DSL would be more code and more brittle.

## Bug fixes (test first)

1. Firebase key default. Change `recommendedKey` default to `Constants.Keys.recommendedVersion`. This is a behavior change, recorded under a Behavior change heading in the CHANGELOG. Justifies the major on its own.
2. Data race in `verifyVersion`. Provider completions append to a shared array concurrently. Fix by accumulating results without a shared mutable array race (per index slots filled under the DispatchGroup, or a lock guarded accumulator). Regression test exercises two providers.
3. Remove dead `osIsNoLongerSupported`.

## Swift 6 and Sendable pass (breaking)

* `AppUpdateType`, `VersionVerifierError`: add `Sendable` and `Equatable`. Equatable is also needed by tests.
* `VersionProviderType`: refine with `Sendable`. Breaking for conformers, flagged in CHANGELOG.
* Closure typealiases (`AppUpdateAction`, `VersionVerifierEmptyAction`, `VersionVerifierStringAction`): mark `@Sendable`.
* Concrete types: `final` where possible. `@MainActor` on `VersionVerifier`, which drives UIKit.
* Replace `UIApplication.shared.windows` with a `connectedScenes` based key window lookup (iOS 15+).
* Replace `print()` with `os.Logger`.
* Verify with `swift build -Xswiftc -strict-concurrency=complete`.

## Async API (additive)

* `VersionVerifier.verifyVersion() async -> Result<VersionProviderResult, VersionVerifierError>`.
* `VersionProviderType.verifyAppVersion() async -> Result<VersionProviderResult, VersionVerifierError>`, with a default implementation that bridges to the existing completion method via `withCheckedContinuation`, so existing conformers do not break.
* The completion handler API stays. Both are documented and tested.

## DocC

Written under `/nerd-swift-docc` conventions.

* Add `Sources/NerdzAppUpdates/Documentation.docc/` with a landing page (`NerdzAppUpdates.md` plus a Topics section) and a Getting Started article.
* `///` on every public symbol, summary first, then parameters, returns, throws. Link related symbols.
* Fix typos, no dash punctuation.
* Build clean, verified with `xcodebuild docbuild`.

## CI and lint

* GitHub Actions macOS job (Linux is not possible here). Steps, `swift build`, `swift test`, and the strict concurrency build, on an iOS destination.
* `.swiftlint.yml` and `.swiftformat` configs.

## Docs and versioning

* README, add async usage examples, update requirements to 3.0.0, add a breaking changes note.
* CHANGELOG `[3.0.0]` with Added, Changed, Removed, Fixed, and a Behavior change note. One line breaking changes summary at the top of the section.
* Update version references consistently.

## Verification gate (run before every merge and the PR)

* `swift build` succeeds.
* `swift build -Xswiftc -strict-concurrency=complete` succeeds.
* `swift test` passes, coverage at 80 percent or better on Sources.
* DocC builds with no warnings.
* README and docs have no dash punctuation, every snippet compiles.
* Each bug fix has a regression test.
* CHANGELOG updated, version references consistent.
* No duplicated literals across arrange and assert in tests.

## Out of scope

* Dropping or adding distribution channels beyond SPM (no CocoaPods present).
* Declaring non iOS platforms (UIKit plus Firebase preclude them).
* Redesigning the provider or update mode public API beyond the Sendable and async additions.
