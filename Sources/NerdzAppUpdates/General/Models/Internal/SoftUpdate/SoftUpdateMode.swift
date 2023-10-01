//
//  SoftUpdateOptions.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

/// Enum with different types that can be used for soft update
public enum SoftUpdateMode {
    /// option that responsible for presenting user screen, first parameter - screen itself, second parameter - is if screen should dissapear with animation
    case screen(SoftUpdateScreenType, Bool)
    
    /// option to present alert on top view controller
    case alert(UIAlertController)
    
    /// option that call closure when soft update is needed 
    case custom(VersionVerifierStringAction)
}
