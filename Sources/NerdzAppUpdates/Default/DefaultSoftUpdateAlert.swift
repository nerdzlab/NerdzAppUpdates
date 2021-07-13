//
//  DefaultSoftUpdateAlert.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import UIKit

public extension SoftUpdateMode {
    
    public enum Constants {
        static let defaultAlertTitle = "Update Available"
        static let defaultAlertMessage = "A new version of app is available. Would you like to update now or later?"
        static let defaultUpdateActionMessage = "Update now"
        static let defaultSkipActionMessage = "Skip for now"
    }
    
    public init(
        alertTitle: String = Constants.defaultAlertTitle,
        alertMessage: String? = Constants.defaultAlertMessage,
        alertUpdateButtonTitle: String = Constants.defaultUpdateActionMessage,
        alertSkipButtonTitle: String = Constants.defaultSkipActionMessage,
        updateHandler: @escaping VersionVerifierEmptyAction,
        skipUpdateHandler: VersionVerifierEmptyAction? = nil
    ) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: alertUpdateButtonTitle,
                style: .default,
                handler: { _ in
                    updateHandler()
                }
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: alertSkipButtonTitle,
                style: .cancel,
                handler: { _ in
                    skipUpdateHandler?()
                }
            )
        )
        
        self = .alert(alert)
    }
}
