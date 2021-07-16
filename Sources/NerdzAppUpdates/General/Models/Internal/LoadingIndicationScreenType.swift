//
//  LoadingIndicationScreenType.swift
//  
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

/// Protocol that should be implemented by user screen that indicate loading of version info
public protocol LoadingIndicationScreenType: UIViewController {
    var onStartLoading: VersionVerifierEmptyAction? { get }
    var onStopLoading: VersionVerifierEmptyAction? { get }
}
