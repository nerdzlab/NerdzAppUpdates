//
//  BackendVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking
import NerdzUtils

/// Version provider for your backend server
public class BackendVersionProvider<BackendRequest: Request>: NSObject, VersionProviderType where BackendRequest.ResponseObjectType: BackendVersionResponseType {

    private let request: BackendRequest
    private let endpoint: Endpoint?

    /// Init version provider with request, that provides version info from your backend
    /// and endpoint on which provider should execute your request
    public init(_ request: BackendRequest, endpoint: Endpoint? = .default) {
        self.request = request
        self.endpoint = endpoint
        
        super.init()
    }
    
    /// Function that perform request to your backend server for retreiving update info
    public func verifyAppVersion(completion: @escaping AppUpdateAction) {
        guard let endpoint = endpoint else {
            completion(.failure(.noEndpointToExecuteOn))
            return
        }
        
        request.execute(on: endpoint)
            
            .onSuccess { [weak self] response in
                
                let updateType = AppUpdateType(
                    recommendedVersion: response.recommendedVersion,
                    requiredVersion: response.requiredVersion
                )
                
                completion(.success(updateType))
            }
            
            .onFail { error in
                completion(.failure(.apiError(error.message)))
            }
    }
}
