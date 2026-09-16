//
//  SoftUpdateOptions.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

/// How ``VersionVerifier`` should present an optional (skippable) update.
public enum SoftUpdateMode {
    /// Presents the given screen as an overlay window.
    ///
    /// The `Bool` parameter controls whether the screen animates away when dismissed.
    case screen(SoftUpdateScreenType, Bool)

    /// Presents the given alert on the top view controller.
    case alert(UIAlertController)

    /// Calls the given closure, passing the latest available version string, when a soft update
    /// is available.
    case custom(VersionVerifierStringAction)
}
