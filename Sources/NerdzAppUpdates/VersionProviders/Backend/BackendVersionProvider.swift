//
//  BackendVersionProvider.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking
import NerdzUtils

public class BackendVersionProvider<BackendRequest: Request>: NSObject, VersionProviderType where BackendRequest.ResponseObjectType: BackendVersionResponseType {

    private let request: BackendRequest
    private let endpoint: Endpoint?

    public init(_ request: BackendRequest, endpoint: Endpoint? = .default) {
        self.request = request
        self.endpoint = endpoint
        
        super.init()
    }
    
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
