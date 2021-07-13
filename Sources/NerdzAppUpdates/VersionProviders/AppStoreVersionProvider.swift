//
//  AppStoreVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking

public class AppStoreVersionProvider: VersionProviderType {
   
    private enum Constants {
        static let iTunesBaseUrl = URL(string: "https://itunes.apple.com")!
    }
    
    public var country: AppStoreCountry
    
    init(country: AppStoreCountry = .unitedStates) {
        self.country = country
    }
    
    private lazy var appStoreEndpoint = Endpoint(baseUrl: Constants.iTunesBaseUrl)
    
    private func handleGetAppInfoRequestSuccess(with data: AppStoreResponseApiModel, completion: @escaping (Result<AppUpdateType, VersionVerifierError>) -> Void) {
        
        guard let currentAppVersion = Bundle.main.currentAppVersion else {
            completion(.failure(.failedToRetreiveCurrentVersion))
            return
        }
        
        guard let appStoreAppInfo = data.results.first else {
            completion(.failure(.theAppWasNotFoundOnAppStore))
            return
        }
        
        guard DataParser.checkIfDeviceOSVersionStillSupported(for: appStoreAppInfo.minimumOSVersion) else {
            completion(.failure(.osIsNoLongerSupported))
            return
        }
        
        let updateType = DataParser.determineUpdateType(with: currentAppVersion, and: appStoreAppInfo.version)
        completion(.success(updateType))
    }
    
    public func verifyAppVersion(completion: @escaping (Result<AppUpdateType, VersionVerifierError>) -> Void) {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            completion(.failure(.unknownError))
            return
        }
        
        GetLatestAppStoreVersionRequest(bundleId: bundleId, countryCode: country.code)
            .execute(on: appStoreEndpoint)
            .onSuccess { [weak self] response in
                self?.handleGetAppInfoRequestSuccess(with: response, completion: completion)
            }
            .onFail { error in
                completion(.failure(.apiError(error.message)))
            }
    }
}
