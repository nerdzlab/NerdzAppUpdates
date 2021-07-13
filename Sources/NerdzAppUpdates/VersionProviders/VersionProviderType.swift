//
//  VersionProviderType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

public protocol VersionProviderType: NSObject {
    func verifyAppVersion(completion: @escaping AppUpdateAction)
}
