//
//  Typealiases.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation

public typealias VersionVerifierEmptyAction = () -> Void
public typealias AppUpdateAction = (Result<AppUpdateType, VersionVerifierError>) -> Void
