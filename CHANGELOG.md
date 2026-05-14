# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
