//
//  VersionProviderType.swift
//  
//
//  Created by Roman Kovalchuk on 13.07.2021.
//

import Foundation

/// Base protocol of version provider
/// In case of custom implementation of version provider, you should implement this protocol
public protocol VersionProviderType: NSObjectProtocol, Sendable {
    func verifyAppVersion(completion: @escaping AppUpdateAction)
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
