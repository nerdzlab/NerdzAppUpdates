//
//  HardUpdateMode.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

/// How ``VersionVerifier`` should present a required (blocking) update.
public enum HardUpdateMode {
    /// Presents the given screen as the window's root view controller.
    case screen(HardUpdateScreenType)

    /// Calls the given closure, passing the latest available version string, when a hard update
    /// is required.
    case custom(VersionVerifierStringAction)
}
