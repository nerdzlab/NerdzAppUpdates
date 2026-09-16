//
//  AppStoreVersionProvider.swift
//
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import NerdzNetworking
import Version

/// A ``VersionProviderType`` that compares the installed app version against the version
/// published on the App Store, using the public iTunes lookup API.
///
/// `@unchecked Sendable` invariant: all stored properties (`appStoreEndpoint`, `country`) are
/// immutable `let` bindings set once at `init` and never mutated afterwards, so instances can be
/// safely shared across isolation domains.
public final class AppStoreVersionProvider: NSObject, VersionProviderType, @unchecked Sendable {
    private enum Constants {
        static let iTunesBaseUrl = URL(string: "https://itunes.apple.com")!
    }

    private let appStoreEndpoint: Endpoint

    /// The App Store country or region this provider queries.
    public let country: AppStoreCountry

    /// Creates a provider that queries the App Store for the given country.
    ///
    /// - Parameter country: The App Store country or region your app is published in. Use a
    ///   country other than ``AppStoreCountry/unitedStates`` if your app is not available on the
    ///   United States App Store.
    public init(country: AppStoreCountry) {
        self.country = country
        appStoreEndpoint = Endpoint(baseUrl: Constants.iTunesBaseUrl)

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

        guard let appStoreVersion = try? Version(appStoreAppInfo.version) else {
            completion(.failure(.failedToParseAppStoreVersion))
            return
        }

        let updateType = AppStoreVersionComparator.updateType(current: currentAppVersion, store: appStoreVersion)
        completion(.success((updateType, appStoreAppInfo.version)))
    }

    /// Checks the installed app version against the version published on the App Store.
    ///
    /// - Parameter completion: Called with the update type and latest App Store version string on
    ///   success, or a ``VersionVerifierError`` on failure.
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
                completion(.failure(.apiError(error.localizedDescription)))
            }
    }
}
