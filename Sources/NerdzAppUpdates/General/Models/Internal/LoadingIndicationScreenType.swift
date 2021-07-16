//
//  LoadingIndicationScreenType.swift
//  
//
//  Created by Roman Kovalchuk on 16.07.2021.
//

import UIKit

public protocol LoadingIndicationScreenType: UIViewController {
    var onStartLoading: VersionVerifierEmptyAction? { get }
    var onStopLoading: VersionVerifierEmptyAction? { get }
}
