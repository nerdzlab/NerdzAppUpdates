//
//  FirebaseConfigVersionProvider.swift
//
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation
import FirebaseRemoteConfig
import NerdzUtils

/// A ``VersionProviderType`` that reads update thresholds from Firebase Remote Config.
///
/// Reads a recommended version key (triggers a soft update) and a required version key (triggers
/// a hard update). Your server controls the policy by setting these values in Remote Config.
///
/// `@unchecked Sendable` invariant: `recommendedKey`/`requiredKey` are immutable `let` bindings.
/// `config` (a Firebase `RemoteConfig` reference type) is likewise a `let` set once at `init` and
/// is only ever accessed from within its own `fetchAndActivate` completion callback, so there is
/// no concurrent mutation of shared state across isolation domains.
public final class FirebaseConfigVersionProvider: NSObject, VersionProviderType, @unchecked Sendable {
    /// Default Remote Config key names used by this provider.
    public enum Constants {
        /// The Remote Config keys read by ``FirebaseConfigVersionProvider``.
        public enum Keys {
            /// The default key for the recommended version, which triggers a soft update.
            public static let recommendedVersion = "recommendedVersion"

            /// The default key for the required version, which triggers a hard update.
            public static let requiredVersion = "requiredVersion"
        }
    }

    private let config: RemoteConfig
    let recommendedKey: String
    let requiredKey: String

    /// Creates a provider that reads update thresholds from the given Remote Config instance.
    ///
    /// - Parameters:
    ///   - config: The Remote Config instance to read from. Defaults to
    ///     `RemoteConfig.remoteConfig()`.
    ///   - recommendedKey: The Remote Config key for the recommended version. Defaults to
    ///     ``Constants/Keys/recommendedVersion``.
    ///   - requiredKey: The Remote Config key for the required version. Defaults to
    ///     ``Constants/Keys/requiredVersion``.
    public init(config: RemoteConfig = .remoteConfig(), recommendedKey: String = Constants.Keys.recommendedVersion, requiredKey: String = Constants.Keys.requiredVersion) {
        self.config = config
        self.recommendedKey = recommendedKey
        self.requiredKey = requiredKey
    }

    /// Fetches and activates Remote Config, then checks the installed app version against the
    /// recommended and required version thresholds.
    ///
    /// - Parameter completion: Called with the update type and latest version string (the
    ///   required version if newer than the recommended one, otherwise the recommended version)
    ///   on success, or a ``VersionVerifierError`` on failure.
    public func verifyAppVersion(completion: @escaping AppUpdateAction) {
        config.fetchAndActivate { [weak self] status, error in
            guard let self else {
                return
            }

            guard status != .error else {
                completion(.failure(.apiError(error?.localizedDescription ?? "Unknown error")))
                return
            }

            let recommendedVersion = config
                .configValue(forKey: recommendedKey)
                .stringValue

            let requiredVersion = config
                .configValue(forKey: requiredKey)
                .stringValue

            let updateType = AppUpdateType(
                recommendedVersion: recommendedVersion,
                requiredVersion: requiredVersion
            )

            let latestVersion = requiredVersion.nz.isVersion(greaterThan: recommendedVersion) ? requiredVersion : recommendedVersion

            completion(.success((updateType, latestVersion)))
        }
    }
}
