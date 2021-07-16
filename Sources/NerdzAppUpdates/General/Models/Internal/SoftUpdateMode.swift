//
//  SoftUpdateOptions.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

public enum SoftUpdateMode {
    case screen(SoftUpdateScreenType, Bool)
    case alert(UIAlertController)
    case custom(VersionVerifierEmptyAction)
}
