//
//  GetLatestAppStoreVersionRequest.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking

struct GetLatestAppStoreVersionRequest: Request {
    
    typealias ResponseObjectType = AppStoreResponseApiModel
    typealias ErrorType = AppStoreErrorResponseModel
    
    let path: String = "lookup"
    let method: HTTPMethod = .get
    let queryParams: [(String, String)]
    
    init(bundleId: String, countryCode: String? = nil) {
        var parameters = [("id", bundleId)]
        
        if let code = countryCode {
            parameters.append(("country", code))
        }
        
        queryParams = parameters
    }
}
