//
//  DataParser.swift
//  NerdzAppUpdatesDemo
//
//  Created by Roman Kovalchuk on 12.07.2021.
//

import UIKit

struct DataParser {
    static func checkIfDeviceOSVersionStillSupported(for appStoreOSMinVersion: String) -> Bool {
        let systemVersion = UIDevice.current.systemVersion

        guard systemVersion.compare(appStoreOSMinVersion, options: .numeric) == .orderedDescending ||
            systemVersion.compare(appStoreOSMinVersion, options: .numeric) == .orderedSame else {
                return false
        }

        return true
    }
    
    static func determineUpdateType(with currentInstalledAppVersion: String, and appStoreAppVersion: String) -> AppUpdateType {
        let oldVersion = split(version: currentInstalledAppVersion)
        let newVersion = split(version: appStoreAppVersion)

        guard let newVersionFirst = newVersion.first,
            let oldVersionFirst = oldVersion.first else {
            return .notNeeded
        }

        if newVersionFirst > oldVersionFirst { // A.b.c.d
            return .hardUpdate
        } else if newVersion.count > 1 && (oldVersion.count <= 1 || newVersion[1] > oldVersion[1]) { // a.B.c.d
            return .softUpdate
        } else if newVersion.count > 2 && (oldVersion.count <= 2 || newVersion[2] > oldVersion[2]) { // a.b.C.d
            return .notNeeded
        } else if newVersion.count > 3 && (oldVersion.count <= 3 || newVersion[3] > oldVersion[3]) { // a.b.c.D
            return .notNeeded
        } else {
            return .notNeeded
        }
    }

    /// Splits a version-formatted `String into an `[Int]`.
    ///
    /// Converts `"a.b.c.d"` into `[a, b, c, d]`.
    ///
    /// - Parameter version: The version formatted `String`.
    ///
    /// - Returns: An array of integers representing a version of the app.
    private static func split(version: String) -> [Int] {
        return version.lazy.split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}
    }
}
