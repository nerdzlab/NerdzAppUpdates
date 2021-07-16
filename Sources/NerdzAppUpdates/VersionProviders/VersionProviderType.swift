//
//  VersionProviderType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

/// Base protocol of version provider
/// In case of custom implementation of version provider, you should implement this protocol
public protocol VersionProviderType: NSObject {
    func verifyAppVersion(completion: @escaping AppUpdateAction)
}
