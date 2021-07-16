//
//  ServerVersionResponseType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

/// Protocol which should be implemented by every version check server response
public protocol BackendVersionResponseType: Decodable {
    var recommendedVersion: String? { get }
    var requiredVersion: String? { get }
}
