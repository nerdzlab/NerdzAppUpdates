//
//  VersionVerifier.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit
import NerdzUtils
import os

/// Class that responsible for version verification
/// Warning - you should store reference to this object in some class, to make sure, object not deinited before version check completed
@MainActor
public final class VersionVerifier {

    private static let logger = Logger(subsystem: "NerdzAppUpdates", category: "VersionVerifier")

    private let softUpdateMode: SoftUpdateMode?
    private let hardUpdateMode: HardUpdateMode?
    private let versionDataProviders: [VersionProviderType]
    private let loadingIndicationMode: LoadingIndicationMode

    /// The app's current key window, resolved via the active `UIWindowScene`s.
    /// Replaces the deprecated `UIApplication.shared.windows` lookup.
    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// To initialize version verifier you should pass
    /// `versionProvider` - object, that responsible for retreiving app update info from server
    /// `loadingIndicationMode` - configuration of loading indication
    /// `softUpdateMode` - configuration of displaying soft update warning
    /// `hardUpdateMode` - configuration of displaying hard update warning
    public init(
        versionDataProvider: VersionProviderType...,
        loadingIndicationMode: LoadingIndicationMode = .none,
        softUpdateMode: SoftUpdateMode? = nil,
        hardUpdateMode: HardUpdateMode? = nil
    ) {
        self.softUpdateMode = softUpdateMode
        self.hardUpdateMode = hardUpdateMode
        self.versionDataProviders = versionDataProvider
        self.loadingIndicationMode = loadingIndicationMode
    }
    
    /// Function that consumes the resolved `UpdatePresentation` and triggers
    /// showing of hard update, soft update, or skips presentation entirely.
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
    
    /// Showing screen for hard update
    /// Warning - be careful, hard update option changes your current window root controller
    private func showScreenForHardUpdate(_ screen: UIViewController) {
        guard let currentWindow = keyWindow else {
            return
        }

        currentWindow.rootViewController = screen
    }
    
    /// Showing screen for soft update
    /// Function adds additional window above your current window
    /// You can dissmiss this window by calling `onDissmiss` in your screen
    /// You can add animations for dismissing screen implementing `animateDissapear` function
    private func showScreenForSoftUpdate(_ screen: SoftUpdateScreenType, animated: Bool) {
        (screen as? UIViewController)?.nz.presentAsOverlay()
        // `onDissmiss`/`animateDissapear` are typed via the now-`@Sendable`
        // `VersionVerifierEmptyAction`, so the compiler can no longer infer that these closure
        // bodies inherit the enclosing @MainActor isolation. Unlike the `notify(queue: .main)`
        // site, a third-party `SoftUpdateScreenType` conformer may invoke these callbacks off the
        // main thread, so we cannot assert isolation (which would hard-trap). Hop to the main actor
        // via `onMain(_:)`, which stays synchronous when already on main (preserving dismiss /
        // animation ordering) and safely dispatches otherwise.
        screen.onDissmiss = { [weak screen, weak self] in
            self?.onMain {
                guard let self else { return }
                if animated {
                    screen?.animateDissapear { [weak screen, weak self] in
                        self?.onMain { self?.dismissScreen(screen) }
                    }
                }
                else {
                    self.dismissScreen(screen)
                }
            }
        }
    }

    /// Runs `work` on the main actor, synchronously if already on the main thread (preserving
    /// call ordering) and via `DispatchQueue.main.async` otherwise. Used for UI callbacks whose
    /// caller thread is not guaranteed, so an off-main invocation is handled instead of trapping.
    /// `nonisolated` so it can be entered from the nonisolated `@Sendable` UI callback closures.
    private nonisolated func onMain(_ work: @escaping @Sendable @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { work() }
        }
        else {
            DispatchQueue.main.async { MainActor.assumeIsolated { work() } }
        }
    }
    
    /// Function that dismiss soft update screen, by removing screen's window
    private func dismissScreen(_ screen: SoftUpdateScreenType?) {
        do {
            try (screen as? UIViewController)?.nz.dismissOverlay()
        }
        catch {
            Self.logger.error("Failed to dismiss soft update overlay")
        }
    }

    /// Showing alert for soft update on top view controller
    private func show(_ alert: UIAlertController) {
        guard let topViewController = keyWindow?.rootViewController?.nz.topController else {
            return
        }
        
        topViewController.present(alert, animated: true)
    }
    
    /// Start loading indication
    private func startLoading() {
        switch loadingIndicationMode {
        case .screen(let screen):
            (screen as? UIViewController)?.nz.presentAsOverlay()
            screen.startLoading()
        case .custom(let onStartLoading, _):
            onStartLoading?()
        case .none: break
        }
    }
    
    /// Stop loading indication
    private func stopLoading() {
        switch loadingIndicationMode {
        case .screen(let screen):
            try? (screen as? UIViewController)?.nz.dismissOverlay()
            screen.stopLoading()
        case .custom(_, let onStopLoading):
            onStopLoading?()
        case .none: break
        }
    }
    
    /// Function wich responsible for version verification
    /// Parameter `completion` is responsible in notifiing api caller about if version check was completed
    /// with error or without and update is not needed
    public func verifyVersion(completion: @escaping AppUpdateAction) {
        startLoading()

        let providers = versionDataProviders
        let resultsBox = ResultsBox(count: providers.count)
        let dispatchGroup = DispatchGroup()

        for (index, provider) in providers.enumerated() {
            dispatchGroup.enter()
            provider.verifyAppVersion { result in
                resultsBox.set(result, at: index)
                dispatchGroup.leave()
            }
        }

        // `DispatchGroup.notify(queue: .main)` hops back to the main queue, but the closure
        // itself is not statically main-actor-isolated as far as the compiler is concerned.
        // `MainActor.assumeIsolated` asserts what we already know at runtime (we are on the
        // main queue) so the @MainActor-isolated `stopLoading()`/`present(_:)` calls below
        // type-check under complete strict concurrency without introducing `async`.
        dispatchGroup.notify(queue: .main) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.stopLoading()

                let outcome = UpdateResolution.selected(from: resultsBox.collected)
                self.present(outcome.presentation)
                completion(outcome.chosen ?? .failure(.unknownError))
            }
        }
    }

    /// Async variant of ``verifyVersion(completion:)``. Presentation still happens on the main actor.
    /// - Returns: The selected provider result, or a failure if none was produced.
    public func verifyVersion() async -> Result<VersionProviderResult, VersionVerifierError> {
        await withCheckedContinuation { continuation in
            verifyVersion { result in
                continuation.resume(returning: result)
            }
        }
    }
}

/// Lock-guarded box collecting per-provider verification results.
///
/// `verifyVersion` fires one `@Sendable` escaping completion per provider, each writing to its
/// own preallocated index. A bare `var [Result?]` captured by multiple `@Sendable` closures is
/// rejected under complete strict concurrency even though each index is only ever written once,
/// so the array is hoisted into this `@unchecked Sendable` box and all access is serialized with
/// an `NSLock`.
private final class ResultsBox: @unchecked Sendable {
    private let lock = NSLock()
    private var results: [Result<VersionProviderResult, VersionVerifierError>?]

    init(count: Int) {
        results = Array(repeating: nil, count: count)
    }

    func set(_ value: Result<VersionProviderResult, VersionVerifierError>, at index: Int) {
        lock.lock()
        results[index] = value
        lock.unlock()
    }

    var collected: [Result<VersionProviderResult, VersionVerifierError>] {
        lock.lock()
        defer { lock.unlock() }
        return results.compactMap { $0 }
    }
}
