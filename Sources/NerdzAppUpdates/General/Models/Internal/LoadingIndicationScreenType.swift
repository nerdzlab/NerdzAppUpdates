//
//  LoadingIndicationScreenType.swift
//  
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

/// Protocol that should be implemented by user screen that indicate loading of version info
public protocol LoadingIndicationScreenType: UIViewController {
    func startLoading()
    func stopLoading()
    func presentAsOverlay()
    func dismissOverlay()
}

public extension LoadingIndicationScreenType {
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
