@testable import NerdzAppUpdates

enum TestData {
    static func success(_ type: AppUpdateType, _ version: String?) -> Result<VersionProviderResult, VersionVerifierError> {
        .success((type, version))
    }

    static func failure(_ error: VersionVerifierError) -> Result<VersionProviderResult, VersionVerifierError> {
        .failure(error)
    }
}
