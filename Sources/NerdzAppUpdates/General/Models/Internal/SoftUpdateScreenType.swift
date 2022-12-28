//
//  File.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

/// Protocol  that should be implemented by every screen that should be presented if soft update needed
/// `onDissmiss` - closur that should be called when user want to skip the update
/// `animateDissapear` - function that responsible for animatig screen dissapearing
public protocol SoftUpdateScreenType: UIViewController {
    var onDissmiss: VersionVerifierEmptyAction? { get set }
    var storeAppVersion: String? { get set }
    
    func animateDissapear(completion: VersionVerifierEmptyAction?)
    func presentAsOverlay()
    func dismissOverlay()
}

public extension SoftUpdateScreenType {
    func animateDissapear(completion: VersionVerifierEmptyAction?) { }
    
    func presentAsOverlay() {
        nz.presentAsOverlay()
    }
    
    func dismissOverlay() {
        do {
            try nz.dismissOverlay()
        }
        catch {
            debugPrint("Version check error, overlay dissmiss")
        }
    }
}
