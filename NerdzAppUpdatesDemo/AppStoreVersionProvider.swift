//
//  AppStoreVersionProvider.swift
//  NerdzAppUpdatesDemo
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation
import NerdzNetworking

struct GetMaximumAppStoreVersionRequest: Request {
    
    typealias ResponseObjectType = AppStoreResponseApiModel
    typealias ErrorType = AppStoreErrorResponseModel
    
    let path: String = "lookup"
    let method: HTTPMethod = .get
    let queryParams: [(String, String)]
    
    init(_ bundleId: String, countryCode: String? = nil) {
        var parameters = [("id", bundleId)]
        
        if let code = countryCode {
            parameters.append(("country", code))
        }
        
        queryParams = parameters
    }
}

struct AppStoreErrorResponseModel: Decodable, ServerError {
    let errorMessage: String?
    
    var message: String {
        return errorMessage ?? "Version check unknown error"
    }
}

struct AppStoreResponseApiModel: Decodable {
    let results: [ResultsResponseApiModel]
}

struct ResultsResponseApiModel: Decodable {

    private enum CodingKeys: String, CodingKey {
        /// The appID JSON key.
        case appID = "trackId"
        /// The current version release date JSON key.
        case currentVersionReleaseDate
        /// The minimum device iOS version compatibility JSON key.
        case minimumOSVersion = "minimumOsVersion"
        /// The release notes JSON key.
        case releaseNotes
        /// The current App Store version JSON key.
        case version
    }

    /// The app's App ID.
    let appID: Int

    /// The release date for the latest version of the app.
    let currentVersionReleaseDate: String

    /// The minimum version of iOS that the current version of the app requires.
    let minimumOSVersion: String

    /// The releases notes from the latest version of the app.
    let releaseNotes: String?

    /// The latest version of the app.
    let version: String
}


class AppStoreVersionProvider: VersionProviderType {
   
    private enum Constants {
        static let iTunesBaseUrl = URL(string: "https://itunes.apple.com")!
    }
    
    private lazy var appStoreEndpoint = Endpoint(baseUrl: Constants.iTunesBaseUrl)
    
    func verifyAppVersion(with completion: @escaping (Result<AppUpdateType, VersionVerifierError>) -> Void) {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            completion(.failure(.unknownError))
            return
        }
        
        GetMaximumAppStoreVersionRequest(bundleId)
            .execute(on: appStoreEndpoint)
            .onSuccess { [weak self] response in
                self?.handleGetAppInfoRequestSucces(with: response, and: completion)
            }
            .onFail { error in
                completion(.failure(.unknownError))
            }

    }
    
    private func handleGetAppInfoRequestSucces(with data: AppStoreResponseApiModel, and completion: @escaping (Result<AppUpdateType, VersionVerifierError>) -> Void) {
        
        guard let currentAppVersion = Bundle.main.currentAppVersion else {
            completion(.failure(.unknownError))
            
            return
        }
        
        guard let appStoreAppInfo = data.results.first else {
            completion(.failure(.unknownError))
            
            return
        }
        
        guard DataParser.checkIfDeviceOSVersionStillSupported(for: appStoreAppInfo.minimumOSVersion) else {
            completion(.failure(.unknownError))
            
            return
        }
        
        let updateType = DataParser.determineUpdateType(with: currentAppVersion, and: appStoreAppInfo.version)
        
        completion(.success(updateType))
    }
}

extension Bundle {
    var currentAppVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
