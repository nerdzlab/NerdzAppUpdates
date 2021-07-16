//
//  AppStoreErrorResponseModel.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking

struct AppStoreErrorResponseModel: Decodable, ServerError {
    let errorMessage: String?
    
    var message: String {
        return errorMessage ?? "Version check unknown error"
    }
}
