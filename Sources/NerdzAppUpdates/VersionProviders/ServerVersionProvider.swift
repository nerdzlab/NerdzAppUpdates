//
//  ServerVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking

public class ServerVersionProvider<ServerRequest: Request>: NSObject, VersionProviderType where ServerRequest.ResponseObjectType: ServerVersionResponseType {

    private let request: ServerRequest
    private let endpoint: Endpoint

    public init(_ request: ServerRequest, endpoint: Endpoint) {
        self.request = request
        self.endpoint = endpoint
        
        super.init()
    }
    
    private func handleGetAppInfoRequestSuccess(
        with data: ServerVersionResponseType,
        completion: @escaping (Result<AppUpdateType, VersionVerifierError>) -> Void
    ) {
        
        guard let currentAppVersion = Bundle.main.currentAppVersion else {
            completion(.failure(.failedToRetreiveCurrentVersion))
            return
        }
        
        guard DataParser.checkIfDeviceOSVersionStillSupported(for: data.minimumSupportedOSVersion) else {
            completion(.failure(.osIsNoLongerSupported))
            return
        }
        
        let updateType = DataParser.determineUpdateType(with: currentAppVersion, and: data.currentVersion)
        completion(.success(updateType))
    }
    
    public func verifyAppVersion(completion: @escaping AppUpdateAction) {
        
        request
            .execute(on: endpoint)
            .onSuccess { [weak self] response in
                self?.handleGetAppInfoRequestSuccess(with: response, completion: completion)
            }
            .onFail { error in
                completion(.failure(.apiError(error.message)))
            }
    }
}
