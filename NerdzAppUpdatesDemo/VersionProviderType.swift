//
//  VersionProviderType.swift
//  NerdzAppUpdatesDemo
//
//  Created by Roman Kovalchuk on 09.07.2021.
//

import Foundation

enum AppUpdateType {
    case softUpdate
    case hardUpdate
    case notNeeded
}

typealias AppUpdateAction = (Result<AppUpdateType, VersionVerifierError>) -> Void

protocol VersionProviderType {
    func verifyAppVersion(with completion: @escaping AppUpdateAction)
}
