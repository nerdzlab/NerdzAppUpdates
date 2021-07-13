//
//  FirebaseConfigVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import FirebaseRemoteConfig
import NerdzUtils

public class FirebaseConfigVersionProvider: NSObject, VersionProviderType {
    
    private enum Constants {
        enum Keys {
            static let recommendedVersion = "recommended-version"
            static let requiredVersion = "required-version"
        }
    }
    
    private let config = RemoteConfig.remoteConfig()
    
    public func verifyAppVersion(completion: @escaping AppUpdateAction) {
        config.fetchAndActivate { status, error in
            if status == .error {
                completion(.failure(.apiError(error?.localizedDescription ?? "Unknown error")))
            }
            
            let recommendedVersion = self
                .config
                .configValue(forKey: Constants.Keys.recommendedVersion)
                .stringValue
            
            let requiredVersion = self
                .config
                .configValue(forKey: Constants.Keys.requiredVersion)
                .stringValue
            
            let updateType = AppUpdateType(
                recommendedVersion: recommendedVersion,
                requiredVersion: requiredVersion
            )
            
            completion(.success(updateType))
        }
    }
}
