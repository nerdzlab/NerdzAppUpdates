/// What the verifier should present after aggregating provider results.
enum UpdatePresentation: Equatable {
    case hardUpdate(latestVersion: String?)
    case softUpdate(latestVersion: String?)
    case none
}

/// Pure selection of the winning result across providers.
/// A hard update takes precedence over a soft update, which takes precedence over no update.
enum UpdateResolution {
    static func selected(
        from results: [Result<VersionProviderResult, VersionVerifierError>]
    ) -> (chosen: Result<VersionProviderResult, VersionVerifierError>?, presentation: UpdatePresentation) {
        var softUpdate: (result: Result<VersionProviderResult, VersionVerifierError>, version: String?)?

        for result in results {
            guard case .success(let checkResult) = result else {
                continue
            }

            switch checkResult.type {
            case .hardUpdate:
                return (result, .hardUpdate(latestVersion: checkResult.latestVersion))

            case .softUpdate where softUpdate == nil:
                softUpdate = (result, checkResult.latestVersion)

            default:
                continue
            }
        }

        if let softUpdate {
            return (softUpdate.result, .softUpdate(latestVersion: softUpdate.version))
        }

        return (results.first, .none)
    }
}
