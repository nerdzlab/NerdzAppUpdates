//
//  LoadingIndicationMode.swift
//  
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

/// Enum with all loading indication mode
public enum LoadingIndicationMode {
    /// option to present screen
    case screen(LoadingIndicationScreenType)
    
    /// option to indicate loading using two closures, first closure indicates start loading, second - indicates stop loading
    case custom(VersionVerifierEmptyAction?, VersionVerifierEmptyAction?)
    
    /// don't indicate loading
    case none
}
