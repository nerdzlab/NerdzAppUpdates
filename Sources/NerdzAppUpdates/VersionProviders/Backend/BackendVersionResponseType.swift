//
//  ServerVersionResponseType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

public protocol BackendVersionResponseType: Decodable {
    var recommendedVersion: String? { get }
    var requiredVersion: String? { get }
}
