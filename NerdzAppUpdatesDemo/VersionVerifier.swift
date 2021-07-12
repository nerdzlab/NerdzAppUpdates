//
//  VersionVerifier.swift
//  NerdzAppUpdatesDemo
//
//  Created by Roman Kovalchuk on 09.07.2021.
//

import UIKit

typealias VersionVerifierCompletionAction = (Result<Void, VersionVerifierError>) -> Void
typealias VersionVerifierEmptyAction = () -> Void

enum HardUpdateOption {
    case screen(UIViewController)
    case custom(VersionVerifierEmptyAction)
}

enum SoftUpdateOption {
    case screen(UIViewController)
    case alert(UIAlertController)
    case custom(VersionVerifierEmptyAction)
}


enum VersionVerifierError: Error {
    case unknownError
    case apiError(Error)
}

class VersionVerifier {
    static let shared = VersionVerifier()
    
    private weak var window: UIWindow?
    
    func verifyVersion(
        using dataProvider: VersionProviderType,
        with softUpdateOption: SoftUpdateOption,
        with hardUpdateOption: HardUpdateOption,
        completion: @escaping VersionVerifierCompletionAction
    ) {
        dataProvider.verifyAppVersion(with: { [weak self] result in
            switch result {
            case .success(let updateType):
                switch updateType {
                case .hardUpdate:
                    switch hardUpdateOption {
                    case .screen(let screen):
                        self?.show(screen)
                    case .custom(let action):
                        action()
                    }
                case .softUpdate:
                    switch softUpdateOption {
                    case .screen(let screen):
                        self?.show(screen)
                    case .alert(let alert):
                        self?.show(alert)
                    case .custom(let action):
                        action()
                    }
                case .notNeeded:
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    private func show(_ screen: UIViewController) {
        let window = UIWindow()
        window.rootViewController = screen
        window.windowLevel = .alert
        window.backgroundColor = .clear
        window.makeKeyAndVisible()
        self.window = window
    }
    
    private func show(_ alert: UIAlertController) {
        guard let topViewController = UIApplication.topViewController() else {
            return
        }
        
        topViewController.present(alert, animated: true)
    }
}

extension UIApplication {

    class func topViewController(
        controller: UIViewController? = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
}
