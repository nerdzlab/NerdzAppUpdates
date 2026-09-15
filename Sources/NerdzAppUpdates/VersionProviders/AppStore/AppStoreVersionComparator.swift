import Version

/// Pure comparison of the installed version against the App Store version.
enum AppStoreVersionComparator {

    /// Decides the update type from two semantic versions.
    /// A lower major triggers a hard update. A matching major with a lower minor triggers a soft update.
    /// - Parameters:
    ///   - current: The installed app version.
    ///   - store: The version reported by the App Store.
    /// - Returns: The resulting update type.
    static func updateType(current: Version, store: Version) -> AppUpdateType {
        if current.major < store.major {
            return .hardUpdate
        }

        if current.major == store.major, let minor = current.minor, let storeMinor = store.minor, minor < storeMinor {
            return .softUpdate
        }

        return .notNeeded
    }
}
