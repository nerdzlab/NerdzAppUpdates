# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0]

**Breaking.** This release adds an async/await API, isolates `VersionVerifier` to the main actor, requires `Sendable` conformance from custom providers, and fixes a Firebase Remote Config default that silently disabled soft updates. Review the Changed and Fixed sections below before upgrading.

### Added

* Async/await API: `VersionVerifier.verifyVersion() async` and `VersionProviderType.verifyAppVersion() async`, with a default implementation bridging to the completion handler API so existing custom providers keep compiling. The completion handler API is unchanged.
* A Swift Testing test suite and code coverage.
* DocC documentation catalog and doc comments for the public API.
* Continuous integration (GitHub Actions, macOS) and SwiftLint/SwiftFormat configuration.

### Changed

* **Breaking.** `VersionProviderType` now refines `Sendable` (and `NSObjectProtocol` instead of `NSObject`). Custom conformers must be safe to share across concurrency domains.
* **Breaking.** `VersionVerifier` is now `@MainActor` isolated and `final`. Call it from the main actor.
* **Breaking.** `AppStoreVersionProvider` and `FirebaseConfigVersionProvider` are now `final`. `AppStoreVersionProvider.country` is now a `let` (set it at initialization).
* **Breaking.** The update action closure typealiases are now `@Sendable`.

### Removed

* Removed the unused `VersionVerifierError.osIsNoLongerSupported` case.

### Fixed

* Fixed a data race in `verifyVersion` where results from multiple providers were collected without synchronization.

### Behavior changes

* `FirebaseConfigVersionProvider` now reads the `recommendedVersion` key by default. Previously the default initializer incorrectly read `requiredVersion` for both the recommended and required values, so soft (recommended) updates were never detected with the default configuration.
* When any provider reports a hard update, it is now always selected as the result, independent of whether a hard update presentation mode is configured. Previously an unconfigured hard update could be skipped and a soft update presented instead. Configure a hard update mode to present it.
* When multiple soft update capable providers are configured, the first soft update result in the provider order is now used (previously the last one was used).

## [2.0.0]

### Changed

* **Breaking.** Bumped Firebase iOS SDK to 12.x (was 11.x).
* **Breaking.** Raised minimum supported iOS version to 15.0 (was 13.0). Required by Firebase 12.
* Bumped Swift tools version to 5.9 (was 5.3). Required to declare iOS 15 as the platform.

### Documentation

* Rewrote `README.md`. Removed references to per-provider installation branches and to the unimplemented `BackendVersionProvider`.
* Added this `CHANGELOG.md`.

### Removed

* Removed all per-provider branches (`provider/appstore`, `provider/backend`, `provider/firebase`) and legacy work branches (`develop`, `feature/loading_indication`) from the remote. Their tips are preserved as `archive/*` tags.

## [1.0.0]

Initial tagged release. Snapshot of the bundled distribution as it stood on `master` at commit `f0ed596`.

### Added

* `AppStoreVersionProvider` for iTunes lookup based version checks (semver). A major version difference triggers a hard update, a minor version difference triggers a soft update.
* `FirebaseConfigVersionProvider` for Firebase Remote Config based version checks. Reads `recommendedVersion` and `requiredVersion` keys.
* `VersionVerifier` with variadic provider input, hard and soft update modes (`.screen`, `.alert`, `.custom`), and optional loading indication (`.screen`, `.custom`, `.none`).
* `VersionProviderType` protocol for custom provider implementations.

Requirements: iOS 13+, Swift 5.3+, Firebase iOS SDK 11.x.
