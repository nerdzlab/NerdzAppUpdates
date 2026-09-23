//
//  Typealiases.swift
//
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import Foundation

/// A closure with no parameters and no return value, used for simple lifecycle callbacks such as
/// dismiss or animation completion.
public typealias VersionVerifierEmptyAction = @Sendable () -> Void

/// The outcome of a version check: the ``AppUpdateType`` that was determined, and the latest
/// version string reported by the provider, if any.
public typealias VersionProviderResult = (type: AppUpdateType, latestVersion: String?)

/// A closure called with the result of a version check, either a ``VersionProviderResult`` on
/// success or a ``VersionVerifierError`` on failure.
public typealias AppUpdateAction = @Sendable (Result<VersionProviderResult, VersionVerifierError>) -> Void

/// A closure called with an optional version string, used by the `.custom(_:)` cases of
/// ``SoftUpdateMode`` and ``HardUpdateMode``.
public typealias VersionVerifierStringAction = @Sendable (String?) -> Void
