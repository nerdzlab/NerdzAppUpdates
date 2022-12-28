//
//  Typealiases.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation

public typealias VersionVerifierCompletionAction = (Result<Void, VersionVerifierError>) -> Void
public typealias VersionVerifierEmptyAction = () -> Void
public typealias AppUpdateAction = (Result<(AppUpdateType, String), VersionVerifierError>) -> Void
public typealias VersionVerifierStringAction = (String) -> Void
