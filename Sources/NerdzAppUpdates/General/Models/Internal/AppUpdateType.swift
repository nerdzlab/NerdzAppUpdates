//
//  AppUpdateType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzUtils

/// Enum with types of updates
public enum AppUpdateType: Equatable, Sendable {
    /// optional update, could be sciped
    case softUpdate
    
    /// required update, user can't skip this update
    case hardUpdate
    
    /// update is not needed
    case notNeeded
    
    init(recommendedVersion: String?, requiredVersion: String?) {
        self.init(
            recommendedVersion: recommendedVersion,
            requiredVersion: requiredVersion,
            currentVersion: Bundle.main.nz.appVersion
        )
    }

    init(recommendedVersion: String?, requiredVersion: String?, currentVersion: String?) {
        guard let currentVersion else {
            self = .notNeeded
            return
        }

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
}
