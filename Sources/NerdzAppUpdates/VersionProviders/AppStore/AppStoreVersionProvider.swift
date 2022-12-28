//
//  AppStoreVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking
import Version

public class AppStoreVersionProvider: NSObject, VersionProviderType {
   
    private enum Constants {
        static let iTunesBaseUrl = URL(string: "https://itunes.apple.com")!
    }
    
    private let appStoreEndpoint: Endpoint
    public var country: AppStoreCountry
    
    /// Init object with country, if your app is not present in usa AppStore
    public init(country: AppStoreCountry) {
        self.country = country
        self.appStoreEndpoint = Endpoint(baseUrl: Constants.iTunesBaseUrl)
        Endpoint.default = appStoreEndpoint
        
        super.init()
    }
    
    /// Function that handle success response from itunes api, and verify app version
    private func handleGetAppInfoRequestSuccess(
        with data: AppStoreResponseApiModel,
        completion: @escaping AppUpdateAction
    ) {
        guard let currentAppVersionString = Bundle.main.nz.appVersion else {
            completion(.failure(.failedToRetreiveCurrentVersion))
            return
        }
        
        guard let currentAppVersion = try? Version(currentAppVersionString) else {
            completion(.failure(.failedToRetreiveCurrentVersion))
            return
        }
        
        guard let appStoreAppInfo = data.results.first else {
            completion(.failure(.theAppWasNotFoundOnAppStore))
            return
        }
        
        guard let appStoreVersion = try? Version(appStoreAppInfo.minimumOSVersion) else {
            completion(.failure(.failedToParseAppStoreVersion))
            return
        }
        
        if currentAppVersion.major > appStoreVersion.major {
            completion(.success((.hardUpdate, currentAppVersionString)))
        }
        else if let minor = currentAppVersion.minor,
                let storeMinor = appStoreVersion.minor,
                minor > storeMinor {
            completion(.success((.softUpdate, currentAppVersionString)))
        }
        else {
            completion(.success((.notNeeded, currentAppVersionString)))
        }
    }
    
    /// Function to verify app using Itunes api
    public func verifyAppVersion(completion: @escaping AppUpdateAction) {
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
