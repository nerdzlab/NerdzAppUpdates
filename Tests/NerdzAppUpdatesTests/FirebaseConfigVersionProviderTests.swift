//
//  FirebaseConfigVersionProviderTests.swift
//
//
//  Created by Roman Kovalchuk on 16.09.2026.
//

import Testing
import FirebaseCore
@testable import NerdzAppUpdates

@Suite("FirebaseConfigVersionProvider")
struct FirebaseConfigVersionProviderTests {

    init() {
        if FirebaseApp.app() == nil {
            let options = FirebaseOptions(googleAppID: "1:1234567890:ios:0123456789abcdef", gcmSenderID: "1234567890")
            options.projectID = "test-project"
            options.apiKey = "A" + String(repeating: "a", count: 38)
            options.bundleID = Bundle.main.bundleIdentifier ?? "com.test.app"
            FirebaseApp.configure(options: options)
        }
    }

    @Test("Default recommended and required keys are distinct")
    func testWhenUsingDefaultKeysShouldBeDistinct() {
        // Arrange
        let recommended = FirebaseConfigVersionProvider.Constants.Keys.recommendedVersion
        let required = FirebaseConfigVersionProvider.Constants.Keys.requiredVersion

        // Act
        let provider = FirebaseConfigVersionProvider()

        // Assert
        #expect(provider.recommendedKey == recommended)
        #expect(provider.requiredKey == required)
        #expect(provider.recommendedKey != provider.requiredKey)
    }
}
