//
//  HardUpdateScreenType.swift
//
//
//  Created by Vasyl Khmil on 01.10.2023.
//

import UIKit

/// A screen that presents a required (blocking) update, for use with ``HardUpdateMode/screen(_:)``.
public protocol HardUpdateScreenType: UIViewController {
    /// The latest available version string, set by ``VersionVerifier`` before presentation.
    var latestVersion: String? { get set }
}
