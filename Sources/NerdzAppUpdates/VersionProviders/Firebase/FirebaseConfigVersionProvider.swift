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
    private let recommendedKey: String
    private let requiredKey: String
    
    public init(recommendedKey: String = Constants.Keys.requiredVersion, requiredKey: String = Constants.Keys.requiredVersion) {
        self.recommendedKey = recommendedKey
        self.requiredKey = requiredKey
    }
    
    /// Function to verify version of the app from firebase
    public func verifyAppVersion(completion: @escaping AppUpdateAction) {
        config.fetchAndActivate { status, error in
            if status == .error {
                completion(.failure(.apiError(error?.localizedDescription ?? "Unknown error")))
            }
            
            let recommendedVersion = self
                .config
                .configValue(forKey: recommendedKey)
                .stringValue
            
            let requiredVersion = self
                .config
                .configValue(forKey: requiredKey)
                .stringValue
            
            let updateType = AppUpdateType(
                recommendedVersion: recommendedVersion,
                requiredVersion: requiredVersion
            )
            
            completion(.success(updateType))
        }
    }
}
