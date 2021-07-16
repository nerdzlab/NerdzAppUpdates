//
//  File.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

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
