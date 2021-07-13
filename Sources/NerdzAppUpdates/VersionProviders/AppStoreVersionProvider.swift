//
//  AppStoreVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking

public class AppStoreVersionProvider: NSObject, VersionProviderType {
   
    private enum Constants {
        static let iTunesBaseUrl = URL(string: "https://itunes.apple.com")!
    }
    
    private let appStoreEndpoint: Endpoint
    public var country: AppStoreCountry
    
    public init(country: AppStoreCountry = .unitedStates) {
        self.country = country
        self.appStoreEndpoint = Endpoint(baseUrl: Constants.iTunesBaseUrl)
        Endpoint.default = appStoreEndpoint
        
        super.init()
    }
    
    
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
                print(response)
                self?.handleGetAppInfoRequestSuccess(with: response, completion: completion)
            }
            .onFail { error in
                print(error)
                completion(.failure(.apiError(error.message)))
            }
    }
}
