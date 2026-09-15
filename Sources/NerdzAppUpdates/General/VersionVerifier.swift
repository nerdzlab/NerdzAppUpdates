//
//  VersionVerifier.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit
import NerdzUtils

/// Class that responsible for version verification
/// Warning - you should store reference to this object in some class, to make sure, object not deinited before version check completed
public class VersionVerifier {

    private let softUpdateMode: SoftUpdateMode?
    private let hardUpdateMode: HardUpdateMode?
    private let versionDataProviders: [VersionProviderType]
    private let loadingIndicationMode: LoadingIndicationMode
    
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
        guard let currentWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else {
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
        screen.onDissmiss = { [weak screen, weak self] in
            if animated {
                screen?.animateDissapear { [weak screen, weak self] in
                    self?.dismissScreen(screen)
                }
            }
            else {
                self?.dismissScreen(screen)
            }
        }
    }
    
    /// Function that dismiss soft update screen, by removing screen's window
    private func dismissScreen(_ screen: SoftUpdateScreenType?) {
        do {
            try (screen as? UIViewController)?.nz.dismissOverlay()
        }
        catch {
            print("Version check error, overlay dissmiss")
        }
    }
    
    /// Showing alert for soft update on top view controller
    private func show(_ alert: UIAlertController) {
        guard let topViewController = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController?.nz.topController else {
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
}
