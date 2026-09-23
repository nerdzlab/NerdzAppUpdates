# NerdzAppUpdates

## About

NerdzAppUpdates is a Swift package that lets an iOS app check whether the installed version is up to date with a distribution service. It supports two update flavors: hard updates (the user must update before continuing) and soft updates (the user is prompted but can skip).

The library ships two built-in version providers:

1. `AppStoreVersionProvider`. Uses the public iTunes lookup API to retrieve the current App Store version, then performs a [semver](https://semver.org/) comparison against the installed `Bundle.main` version. A different major triggers a hard update (for example, installed `1.0.0` vs. store `2.0.0`). A different minor triggers a soft update (for example, installed `0.2.0` vs. store `0.3.0`).
2. `FirebaseConfigVersionProvider`. Reads `recommendedVersion` and `requiredVersion` from Firebase Remote Config. Your server controls the policy, so the threshold for hard and soft updates is whatever you set in Remote Config.

You can also implement your own provider by conforming to `VersionProviderType`. This is the recommended path when version policy comes from your own backend.

## Installation

Add the package via Swift Package Manager and depend on the `master` branch (or a tagged release once one is published):

```
.package(url: "https://github.com/nerdzlab/NerdzAppUpdates.git", branch: "master")
```

Requirements:

* iOS 15 or later.
* Swift 5.9 or later.
* Firebase iOS SDK 12.x (pulled transitively).

Note. Earlier versions of this project documented installation from per-provider branches (`provider/appstore`, `provider/backend`, `provider/firebase`). Those branches are archived and no longer maintained. Use `master`.

## Usage example

Below is a minimal `UIApplicationDelegate` that wires up `AppStoreVersionProvider` with a custom loading screen, a soft update screen, and a hard update screen.

```swift
import NerdzAppUpdates
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private lazy var versionVerifier: VersionVerifier = {
        let provider = AppStoreVersionProvider(country: .germany)

        return VersionVerifier(
            versionDataProvider: provider,
            loadingIndicationMode: .screen(LoaderScreen()),
            softUpdateMode: .screen(SoftUpdateScreen(), true),
            hardUpdateMode: .screen(HardUpdateScreen())
        )
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        verifyVersion()
        return true
    }

    private func verifyVersion() {
        versionVerifier.verifyVersion { [weak self] result in
            guard case .failure(let error) = result else {
                return
            }
            self?.showError(error.localizedDescription)
        }
    }
}
```

Key points:

* `VersionVerifier` accepts one or more providers (variadic). Pass several if you want App Store and Remote Config results combined in a single check.
* `loadingIndicationMode` is optional. Use `.screen(_:)` for a full-screen loader (typically a copy of your launch storyboard), `.custom(onStart:onStop:)` to drive your own indicator, or `.none`.
* `softUpdateMode` supports `.screen(_:animated:)`, `.alert(_:)`, and `.custom(_:)`.
* `hardUpdateMode` supports `.screen(_:)` and `.custom(_:)`. The screen variant replaces the key window's root view controller, so the user cannot dismiss it without updating.

## Async usage

`VersionVerifier` also exposes an `async` API that returns the same `Result` the completion handler receives. Both APIs are `@MainActor` isolated, so call them from the main actor (for example from a SwiftUI `.task` or an `async` `AppDelegate` method).

```swift
@MainActor
private func verifyVersion() async {
    let result = await versionVerifier.verifyVersion()

    guard case .failure(let error) = result else {
        return
    }
    showError(error.localizedDescription)
}
```

Custom `VersionProviderType` conformers do not need to implement `verifyAppVersion() async` themselves. A default implementation bridges it to `verifyAppVersion(completion:)`, so existing providers keep compiling unchanged.

## Pay attention

1. Keep a strong reference to the `VersionVerifier` instance until `verifyVersion` calls back. If the object is deallocated mid-check, the completion never fires, and an awaiting `verifyVersion() async` call never resumes.
2. When using `AppStoreVersionProvider`, pass the correct country in the initializer. The default country list lives in [`AppStoreCountry.swift`](Sources/NerdzAppUpdates/VersionProviders/AppStore/AppStoreCountry.swift).
3. The hard update flow swaps the key window's root view controller. Make sure any global state (analytics, background tasks) tolerates that.

## Breaking changes in 3.0.0

`VersionVerifier` is now `@MainActor` isolated and `final`, `VersionProviderType` now refines `Sendable`, and `FirebaseConfigVersionProvider` now reads the `recommendedVersion` key by default (previously it incorrectly read `requiredVersion` for both thresholds). See [`CHANGELOG.md`](CHANGELOG.md) for the full list of breaking and behavior changes before upgrading.

## License

MIT. See [`LICENSE`](LICENSE).
