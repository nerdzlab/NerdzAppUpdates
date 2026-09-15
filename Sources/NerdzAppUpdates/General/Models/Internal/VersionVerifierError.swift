//
//  VersionVerifierError.swift
//  
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation

public enum VersionVerifierError: Error, Equatable, Sendable {
    case unknownError
    case failedToRetreiveCurrentVersion
    case apiError(String)
    
    /// AppStore
    case theAppWasNotFoundOnAppStore
    case failedToParseAppStoreVersion

}
