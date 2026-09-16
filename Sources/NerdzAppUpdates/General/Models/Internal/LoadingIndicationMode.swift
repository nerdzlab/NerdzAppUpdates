//
//  LoadingIndicationMode.swift
//  
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

/// How ``VersionVerifier`` should indicate that a version check is in progress.
public enum LoadingIndicationMode {
    /// Presents the given screen while the check is in progress.
    case screen(LoadingIndicationScreenType)

    /// Calls the first closure when loading starts and the second closure when loading stops.
    case custom(VersionVerifierEmptyAction?, VersionVerifierEmptyAction?)

    /// Does not indicate loading.
    case none
}
