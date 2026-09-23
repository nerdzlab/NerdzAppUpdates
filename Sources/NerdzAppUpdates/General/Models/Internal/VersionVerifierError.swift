//
//  VersionVerifierError.swift
//
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation

/// Errors that can occur while verifying the app version.
public enum VersionVerifierError: Error, Equatable, Sendable {
    /// An unspecified error occurred and no more specific case applies.
    case unknownError

    /// The installed app's current version could not be determined from the app bundle.
    case failedToRetreiveCurrentVersion

    /// A provider's network or backend request failed.
    ///
    /// The associated value contains a human readable description of the underlying error.
    case apiError(String)

    /// The app could not be found on the App Store for the configured ``AppStoreCountry``.
    case theAppWasNotFoundOnAppStore

    /// The version string returned by the App Store could not be parsed as a semantic version.
    case failedToParseAppStoreVersion
}
