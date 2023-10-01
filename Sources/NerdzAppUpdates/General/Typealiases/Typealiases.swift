//
//  Typealiases.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation

public typealias VersionVerifierEmptyAction = () -> Void
public typealias VersionProviderResult = (type: AppUpdateType, latestVersion: String?)
public typealias AppUpdateAction = (Result<VersionProviderResult, VersionVerifierError>) -> Void
public typealias VersionVerifierStringAction = (String?) -> Void
