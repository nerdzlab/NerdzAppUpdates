//
//  LoadingIndicationMode.swift
//  
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

public enum LoadingIndicationMode {
    case screen(LoadingIndicationScreenType)
    case custom(VersionVerifierEmptyAction?, VersionVerifierEmptyAction?)
    case none
}
