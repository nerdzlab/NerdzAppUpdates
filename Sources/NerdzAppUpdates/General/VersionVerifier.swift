//
//  VersionVerifier.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

public class VersionVerifier {

    private let softUpdateMode: SoftUpdateMode
    private let hardUpdateMode: HardUpdateMode
    private let versionDataProvider: VersionProviderType
    private let loadingIndicationMode: LoadingIndicationMode
    
    /// To initialize version verifier you should pass
    public init(
        versionDataProvider: VersionProviderType,
        loadingIndicationMode: LoadingIndicationMode,
        softUpdateMode: SoftUpdateMode,
        hardUpdateMode: HardUpdateMode
    ) {
        self.softUpdateMode = softUpdateMode
        self.hardUpdateMode = hardUpdateMode
        self.versionDataProvider = versionDataProvider
        self.loadingIndicationMode = loadingIndicationMode
    }
    
    private func handleDataProviderVersionVerification(
        with result: Result<AppUpdateType, VersionVerifierError>,
        completion: VersionVerifierCompletionAction?
    ) {
        switch result {
        case .success(let updateType):
            switch updateType {
            case .hardUpdate:
                
                switch hardUpdateMode {
                case .screen(let screen):
                    showScreenForHardUpdate(screen)
                case .custom(let action):
                    action()
                }
                
            case .softUpdate:
                
                switch softUpdateMode {
                case .screen(let screen):
                    showScreenForSoftUpdate(screen)
                case .alert(let alert):
                    show(alert)
                case .custom(let action):
                    action()
                }
                
            case .notNeeded:
                completion?(.success(()))
            }
            
        case .failure(let error):
            completion?(.failure(error))
        }
    }
    
    private func showScreenForHardUpdate(_ screen: UIViewController) {
        guard let currentWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else {
            return
        }
        
        currentWindow.rootViewController = screen
    }
    
    private func showScreenForSoftUpdate(_ screen: SoftUpdateScreenType) {
        screen.presentAsOverlay()
        screen.onDissmiss = { [weak screen] in
            do {
                try screen?.dismissOverlay()
            }
            catch {
                print("Version check error, overlay dissmiss")
            }
        }
    }
    
    private func show(_ alert: UIAlertController) {
        guard let topViewController = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController?.topController else {
            return
        }
        
        topViewController.present(alert, animated: true)
    }
    
    private func startLoading() {
        switch loadingIndicationMode {
        case .screen(let screen):
            screen.onStartLoading?()
        case .custom(let onStartLoading, _):
            onStartLoading?()
        case .none: break
        }
    }
    
    private func stopLoading() {
        switch loadingIndicationMode {
        case .screen(let screen):
            screen.onStopLoading?()
        case .custom(_, let onStopLoading):
            onStopLoading?()
        case .none: break
        }
    }
    
    public func verifyVersion(completion: @escaping VersionVerifierCompletionAction) {
        startLoading()
        versionDataProvider.verifyAppVersion { [weak self] result in
            self?.stopLoading()
            self?.handleDataProviderVersionVerification(with: result, completion: completion)
        }
    }
}
