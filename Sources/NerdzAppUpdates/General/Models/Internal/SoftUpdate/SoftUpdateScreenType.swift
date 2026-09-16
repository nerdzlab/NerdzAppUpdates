//
//  File.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

/// A screen that presents an optional (skippable) update, for use with
/// ``SoftUpdateMode/screen(_:_:)``.
///
/// Call `onDissmiss` when the user wants to skip the update, and implement `animateDissapear` to
/// animate the screen away before it is dismissed.
public protocol SoftUpdateScreenType: UIViewController {
    /// The latest available version string, set by ``VersionVerifier`` before presentation.
    var latestVersion: String? { get set }

    /// Called by your screen when the user wants to skip the update and dismiss it.
    var onDissmiss: VersionVerifierEmptyAction? { get set }

    /// The version string currently installed on the device, if known.
    var storeAppVersion: String? { get set }

    /// Animates the screen disappearing, then calls `completion`.
    ///
    /// - Parameter completion: Called once the disappear animation finishes.
    func animateDissapear(completion: VersionVerifierEmptyAction?)

    /// Presents this screen as an overlay window above the current key window.
    func presentAsOverlay()

    /// Dismisses the overlay window presented by ``presentAsOverlay()``.
    func dismissOverlay()
}

public extension SoftUpdateScreenType {
    /// Default implementation that performs no animation and does not call `completion`.
    /// Override this to animate the screen away and call `completion` when finished.
    func animateDissapear(completion: VersionVerifierEmptyAction?) { }

    /// Default implementation that presents this screen as an overlay window.
    func presentAsOverlay() {
        nz.presentAsOverlay()
    }

    /// Default implementation that dismisses the overlay window.
    func dismissOverlay() {
        do {
            try nz.dismissOverlay()
        }
        catch {
            debugPrint("Version check error, overlay dismiss")
        }
    }
}
