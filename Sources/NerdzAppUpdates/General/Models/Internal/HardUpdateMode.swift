//
//  HardUpdateMode.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

public protocol HardUpdateScreenType: UIViewController {
    var storeAppVersion: String? { get set }
}

/// Enum with different types that can be used for hard update
public enum HardUpdateMode {
    /// present screen
    case screen(HardUpdateScreenType)
    
    /// execute closure when update is required
    case custom(VersionVerifierStringAction)
}
