//
//  VersionProviderType.swift
//
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

/// A type that retrieves app update information from a distribution service.
///
/// Conform to this protocol to implement a custom version provider, for example one backed by
/// your own server. ``AppStoreVersionProvider`` and ``FirebaseConfigVersionProvider`` are the
/// built in conformers.
public protocol VersionProviderType: NSObjectProtocol, Sendable {
    /// Checks the installed app version against this provider's source and reports the outcome.
    ///
    /// - Parameter completion: Called with the update type and latest version string on success,
    ///   or a ``VersionVerifierError`` on failure.
    func verifyAppVersion(completion: @escaping AppUpdateAction)

    /// Async variant of ``verifyAppVersion(completion:)``.
    ///
    /// A default implementation bridges to the completion based requirement, so most conformers
    /// only need to implement ``verifyAppVersion(completion:)``.
    ///
    /// - Returns: The update type and latest version string on success, or a
    ///   ``VersionVerifierError`` on failure.
    func verifyAppVersion() async -> Result<VersionProviderResult, VersionVerifierError>
}

public extension VersionProviderType {
    /// Default async bridge to ``verifyAppVersion(completion:)``, so existing conformers
    /// keep compiling without implementing the async requirement themselves.
    func verifyAppVersion() async -> Result<VersionProviderResult, VersionVerifierError> {
        await withCheckedContinuation { continuation in
            verifyAppVersion { result in
                continuation.resume(returning: result)
            }
        }
    }
}
