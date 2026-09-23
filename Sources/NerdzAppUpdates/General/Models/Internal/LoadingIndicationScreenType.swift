//
//  LoadingIndicationScreenType.swift
//
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

/// A screen that indicates version check loading, for use with ``LoadingIndicationMode/screen(_:)``.
public protocol LoadingIndicationScreenType: UIViewController {
    /// Called when the version check starts. Start your loading animation here.
    func startLoading()

    /// Called when the version check finishes. Stop your loading animation here.
    func stopLoading()

    /// Presents this screen as an overlay window above the current key window.
    func presentAsOverlay()

    /// Dismisses the overlay window presented by ``presentAsOverlay()``.
    func dismissOverlay()
}

public extension LoadingIndicationScreenType {
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
