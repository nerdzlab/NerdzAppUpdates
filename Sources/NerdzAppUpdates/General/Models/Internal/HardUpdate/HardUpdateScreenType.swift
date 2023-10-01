//
//  File.swift
//  
//
//  Created by Vasyl Khmil on 01.10.2023.
//

import UIKit

public protocol HardUpdateScreenType: UIViewController {
    var latestVersion: String? { get set }
}
