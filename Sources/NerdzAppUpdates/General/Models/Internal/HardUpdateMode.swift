//
//  HardUpdateMode.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

public enum HardUpdateMode {
    case screen(UIViewController)
    case custom(VersionVerifierEmptyAction)
}
