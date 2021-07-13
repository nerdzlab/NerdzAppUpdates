//
//  File.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

public protocol SoftUpdateScreenType: UIViewController {
    var onDissmiss: VersionVerifierEmptyAction? { get set }
}
