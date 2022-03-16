//
//  AppUpdateType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzUtils

/// Enum with types of updates
public enum AppUpdateType {
    /// optional update, could be sciped
    case softUpdate
    
    /// required update, user can't skip this update
    case hardUpdate
    
    /// update is not needed
    case notNeeded
    
    init(recommendedVersion: String?, requiredVersion: String?) {
        if let currentVersion = Bundle.main.nz.appVersion {
            if requiredVersion?.nz.isVersion(greaterThan: currentVersion) == true {
                self = .hardUpdate
            }
            else if recommendedVersion?.nz.isVersion(greaterThan: currentVersion) == true {
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
