import Foundation
import Testing
@testable import Updeto

@Suite(.serialized)
struct UpdetoLiveIntegrationTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["UPDETO_RUN_LIVE_TESTS"] == "1"))
    func liveLookup_optIn() async throws {
        let bundleId = try #require(
            ProcessInfo.processInfo.environment["UPDETO_LIVE_BUNDLE_ID"],
            "Set UPDETO_LIVE_BUNDLE_ID to a known App Store bundle identifier"
        )
        #expect(!bundleId.isEmpty)

        let country = ProcessInfo.processInfo.environment["UPDETO_LIVE_COUNTRY"]
        let installedVersion = ProcessInfo.processInfo.environment["UPDETO_LIVE_INSTALLED_VERSION"] ?? "0"

        let provider = AppStoreProvider(
            bundleId: bundleId,
            installedAppVersion: installedVersion,
            country: country,
            requestTimeout: 20,
            retryCount: 1
        )

        let result = await withCheckedContinuation { continuation in
            provider.updateInfoResult { output in
                continuation.resume(returning: output)
            }
        }

        switch result {
        case .success(let info):
            #expect(info.bundleId == bundleId)
            #expect(!info.installedVersion.isEmpty)
        case .failure(let error):
            Issue.record("Live lookup failed: \(error)")
        }
    }
}
