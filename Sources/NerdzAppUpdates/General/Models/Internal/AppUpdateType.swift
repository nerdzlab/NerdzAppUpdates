//
//  AppUpdateType.swift
//
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzUtils

/// The kind of update, if any, that a version provider determined is available.
public enum AppUpdateType: Equatable, Sendable {
    /// An optional update. The user can skip it and continue using the current version.
    case softUpdate

    /// A required update. The user cannot continue without updating.
    case hardUpdate

    /// No update is needed. The installed version is up to date.
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
