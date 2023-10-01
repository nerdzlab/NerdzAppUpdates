//
//  VersionVerifier.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

/// Class that responsible for version verification
/// Warning - you should store reference to this object in some class, to make sure, object not deinited before version check completed
public class VersionVerifier {

    private let softUpdateMode: SoftUpdateMode?
    private let hardUpdateMode: HardUpdateMode?
    private let versionDataProvider: VersionProviderType
    private let loadingIndicationMode: LoadingIndicationMode
    
    /// To initialize version verifier you should pass
    /// `versionProvider` - object, that responsible for retreiving app update info from server
    /// `loadingIndicationMode` - configuration of loading indication
    /// `softUpdateMode` - configuration of displaying soft update warning
    /// `hardUpdateMode` - configuration of displaying hard update warning
    public init(
        versionDataProvider: VersionProviderType,
        loadingIndicationMode: LoadingIndicationMode = .none,
        softUpdateMode: SoftUpdateMode? = nil,
        hardUpdateMode: HardUpdateMode? = nil
    ) {
        self.softUpdateMode = softUpdateMode
        self.hardUpdateMode = hardUpdateMode
        self.versionDataProvider = versionDataProvider
        self.loadingIndicationMode = loadingIndicationMode
    }
    
    /// Function that handle version provider completion
    /// and triggers showing of hard update and soft update, or skiping app update
    private func handleDataProviderVersionVerification(
        with result: Result<VersionProviderResult, VersionVerifierError>
    ) {
        switch result {
        case .success(let checkResult):
            switch checkResult.type {
            case .hardUpdate:
                guard let hardUpdateMode = hardUpdateMode else {
                    break
                }
                
                switch hardUpdateMode {
                case .screen(let screen):
                    screen.latestVersion = checkResult.latestVersion
                    showScreenForHardUpdate(screen)
                    
                case .custom(let action):
                    action(checkResult.latestVersion)
                }
                
            case .softUpdate:
                guard let softUpdateMode = softUpdateMode else {
                    break
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
                
            case .notNeeded:
                return
            }
            
        case .failure:
            return
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
        screen.presentAsOverlay()
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
            try screen?.dismissOverlay()
        }
        catch {
            print("Version check error, overlay dissmiss")
        }
    }
    
    /// Showing alert for soft update on top view controller
    private func show(_ alert: UIAlertController) {
        guard let topViewController = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController?.topController else {
            return
        }
        
        topViewController.present(alert, animated: true)
    }
    
    /// Start loading indication
    private func startLoading() {
        switch loadingIndicationMode {
        case .screen(let screen):
            screen.presentAsOverlay()
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
            try? screen.dismissOverlay()
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
        versionDataProvider.verifyAppVersion { [weak self] result in
            self?.stopLoading()
            self?.handleDataProviderVersionVerification(with: result)
            completion(result)
        }
    }
}
