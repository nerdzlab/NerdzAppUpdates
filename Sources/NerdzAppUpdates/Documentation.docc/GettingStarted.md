# Getting Started

Wire up ``VersionVerifier`` with a version provider and run a check at launch.

## Overview

This article walks through a minimal setup using ``AppStoreVersionProvider``, which compares the installed app version against the public iTunes lookup API. The same pattern applies to ``FirebaseConfigVersionProvider`` or a custom ``VersionProviderType`` conformer.

## Add the dependency

Add the package via Swift Package Manager, depending on the `master` branch (or a tagged release once one is published):

```swift
.package(url: "https://github.com/nerdzlab/NerdzAppUpdates.git", branch: "master")
```

## Create and retain a verifier

Keep a strong reference to the ``VersionVerifier`` instance for as long as the check is in flight. If it deallocates before the check completes, the completion closure never fires and an awaiting async call never resumes.

```swift
import NerdzAppUpdates
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private lazy var versionVerifier: VersionVerifier = {
        let provider = AppStoreVersionProvider(country: .germany)

        return VersionVerifier(
            versionDataProvider: provider,
            loadingIndicationMode: .none,
            softUpdateMode: nil,
            hardUpdateMode: nil
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

    private func showError(_ message: String) {
        // Surface the error however fits your app.
    }
}
```

## Use the async variant

``VersionVerifier/verifyVersion()`` mirrors ``VersionVerifier/verifyVersion(completion:)`` for callers using structured concurrency. The same retention rule applies, since the continuation never resumes if the verifier is deallocated first.

```swift
func verifyVersion() async {
    let result = await versionVerifier.verifyVersion()

    if case .failure(let error) = result {
        showError(error.localizedDescription)
    }
}
```

## Configure presentation

`softUpdateMode` and `hardUpdateMode` are optional and default to `nil`, so pass `nil` to skip that prompt. `loadingIndicationMode` is not optional and defaults to `.none`. Supply a `.screen(_:)` case (for the loader and hard update) or a `.screen(_:_:)` case (for the soft update, which also takes an animated `Bool`) with your own view controllers to present a loader, a soft update prompt, or a blocking hard update screen, or use `.custom(_:)` to drive your own UI. See ``LoadingIndicationMode``, ``SoftUpdateMode``, and ``HardUpdateMode`` for every option.

## See Also

- ``VersionVerifier``
- ``VersionProviderType``
- ``AppStoreVersionProvider``
- ``FirebaseConfigVersionProvider``
