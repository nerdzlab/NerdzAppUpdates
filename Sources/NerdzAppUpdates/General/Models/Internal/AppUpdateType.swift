//
//  AppUpdateType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzUtils

public enum AppUpdateType {
    case softUpdate
    case hardUpdate
    case notNeeded
    
    init(recommendedVersion: String?, requiredVersion: String?) {
        if let currentVersion = Bundle.main.appVersion {
            if requiredVersion?.isVersion(greaterThan: currentVersion) == true {
                self = .hardUpdate
            }
            else if recommendedVersion?.isVersion(greaterThan: currentVersion) == true {
                self = .softUpdate
            }
            else {
                self = .notNeeded
            }
        }
        else {
            self = .notNeeded
        }
    }
}
