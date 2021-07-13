//
//  ServerVersionResponseType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

public protocol ServerVersionResponseType: Decodable {
    var minimumSupportedOSVersion: String { get }
    var currentVersion: String { get }
}
