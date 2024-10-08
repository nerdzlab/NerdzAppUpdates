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
    
    /// Function that handle version provider completion
    /// and triggers showing of hard update and soft update, or skiping app update
    private func handleDataProviderVersionVerification(
        with results: [Result<VersionProviderResult, VersionVerifierError>]
    ) -> Result<VersionProviderResult, VersionVerifierError>? {
        
        var softUpdateResult: Result<VersionProviderResult, VersionVerifierError>?
        
        for result in results {
            switch result {
            case .success(let checkResult):
                switch checkResult.type {
                case .hardUpdate:
                    guard let hardUpdateMode = hardUpdateMode else {
                        continue
                    }
                    
                    switch hardUpdateMode {
                    case .screen(let screen):
                        screen.latestVersion = checkResult.latestVersion
                        showScreenForHardUpdate(screen)
                        
                    case .custom(let action):
                        action(checkResult.latestVersion)
                    }
                    
                    return result
                    
                case .softUpdate:
                    softUpdateResult = result
                    continue
                    
                case .notNeeded:
                    continue
                }
                
            case .failure:
                continue
            }
        }
        
        if case .success(let checkResult) = softUpdateResult, checkResult.type == .softUpdate {
            guard let softUpdateMode = softUpdateMode else {
                return softUpdateResult
            }
            
            switch softUpdateMode {
            case .screen(let screen, let animated):
                screen.latestVersion = checkResult.latestVersion
                showScreenForSoftUpdate(screen, animated: animated)
                
            case .alert(let alert):
                show(alert)
                
            case .custom(let action):
                action(checkResult.latestVersion)
            }
            
            return softUpdateResult
        }
        else {
            return results.first
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
        
        var results: [Result<VersionProviderResult, VersionVerifierError>] = []
        
        let dispatchGroup = DispatchGroup()
        
        for versionDataProvider in versionDataProviders {
            dispatchGroup.enter()
            versionDataProvider.verifyAppVersion { result in
                results.append(result)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.stopLoading()
            
            let result = self?.handleDataProviderVersionVerification(with: results) ?? .failure(.unknownError)
            
            completion(result)
        }
    }
}
