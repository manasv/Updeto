import Foundation
import Testing
@testable import Updeto

@Suite(.serialized)
struct UpdetoTests {
    @Test
    func compareVersions_normalizesComponents() {
        let provider = AppStoreProvider(bundleId: "com.example.app", installedAppVersion: "1.2", country: nil)

        #expect(provider.compareVersions("1.2.0", "1.2") == .orderedSame)
        #expect(provider.compareVersions("1.2.1", "1.2") == .orderedDescending)
        #expect(provider.compareVersions("1.1.9", "1.2") == .orderedAscending)
    }

    @Test
    func updateInfo_completion_containsRichMetadata() async {
        defer { MockURLProtocol.requestHandler = nil }

        let payload = #"{"resultCount":1,"results":[{"version":"2.0.0","bundleId":"com.example.app","trackId":1234567890}]}"#
        let provider = makeProvider(
            bundleId: "com.example.app",
            installedVersion: "1.0.0",
            country: "us",
            payload: payload,
            requestTimeout: 30
        )

        let info = await awaitUpdateInfo(provider)

        #expect(info.result == .outdated)
        #expect(info.installedVersion == "1.0.0")
        #expect(info.storeVersion == "2.0.0")
        #expect(info.appId == "1234567890")
        #expect(info.bundleId == "com.example.app")
        #expect(info.country == "US")
        #expect(info.appStoreURL?.absoluteString == "itms-apps://apple.com/app/id1234567890")
        #expect(info.isUpdateAvailable)
    }

    @Test
    func isAppUpdated_completion_returnsOutdatedAndUpdatesAppId() async {
        defer { MockURLProtocol.requestHandler = nil }

        let payload = #"{"resultCount":1,"results":[{"version":"2.0.0","bundleId":"com.example.app","trackId":1234567890}]}"#
        let provider = makeProvider(
            bundleId: "com.example.app",
            installedVersion: "1.0.0",
            country: "US",
            payload: payload
        )

        let result = await awaitAppUpdated(provider)

        #expect(result == .outdated)
        #expect(provider.appId == "1234567890")
    }

    @Test
    func isAppUpdatedResult_completion_returnsDecodingError() async {
        defer { MockURLProtocol.requestHandler = nil }

        let provider = makeProvider(
            bundleId: "com.example.app",
            installedVersion: "1.0.0",
            country: "US",
            payload: "invalid-json"
        )

        let result = await awaitAppUpdatedResult(provider)

        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            #expect(error == .decoding)
        }
    }

    @Test
    func isAppUpdatedResult_completion_retriesAndSucceedsOnSecondAttempt() async {
        defer { MockURLProtocol.requestHandler = nil }

        var attempts = 0
        let provider = makeProviderWithHandler(bundleId: "com.example.app", installedVersion: "1.0.0", country: "US", retryCount: 1) { request in
            attempts += 1
            let statusCode = attempts == 1 ? 500 : 200
            let payload = attempts == 1
                ? #"{"resultCount":0,"results":[]}"#
                : #"{"resultCount":1,"results":[{"version":"1.1.0","bundleId":"com.example.app","trackId":999}]}"#

            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, Data(payload.utf8))
        }

        let result = await awaitAppUpdatedResult(provider)

        switch result {
        case .success(let status):
            #expect(status == .outdated)
            #expect(attempts == 2)
        case .failure(let error):
            Issue.record("Expected success, got \(error)")
        }
    }

    @Test
    func countryAndTimeoutAppliedToRequest() async {
        defer { MockURLProtocol.requestHandler = nil }

        let payload = #"{"resultCount":0,"results":[]}"#
        let provider = makeProvider(
            bundleId: "com.example.app",
            installedVersion: "1.0.0",
            country: "es",
            payload: payload,
            requestTimeout: 42
        )

        _ = await awaitAppUpdated(provider)
    }

    @Test
    func isAppUpdatedResult_async_returnsOutdated() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        let payload = #"{"resultCount":1,"results":[{"version":"3.0.0","bundleId":"com.example.app","trackId":111}]}"#
        let provider = makeProvider(
            bundleId: "com.example.app",
            installedVersion: "2.9.0",
            country: "US",
            payload: payload
        )

        let result = try await provider.isAppUpdatedResult()

        #expect(result == .outdated)
        #expect(provider.appId == "111")
    }

    private func awaitUpdateInfo(_ provider: AppStoreProvider) async -> AppStoreUpdateInfo {
        await withCheckedContinuation { continuation in
            provider.updateInfo { info in
                continuation.resume(returning: info)
            }
        }
    }

    private func awaitAppUpdated(_ provider: AppStoreProvider) async -> AppStoreLookupResult {
        await withCheckedContinuation { continuation in
            provider.isAppUpdated { result in
                continuation.resume(returning: result)
            }
        }
    }

    private func awaitAppUpdatedResult(_ provider: AppStoreProvider) async -> Result<AppStoreLookupResult, UpdetoError> {
        await withCheckedContinuation { continuation in
            provider.isAppUpdatedResult { result in
                continuation.resume(returning: result)
            }
        }
    }

    private func makeProvider(
        bundleId: String,
        installedVersion: String,
        country: String?,
        payload: String,
        statusCode: Int = 200,
        requestTimeout: TimeInterval = 15,
        retryCount: Int = 0
    ) -> AppStoreProvider {
        makeProviderWithHandler(
            bundleId: bundleId,
            installedVersion: installedVersion,
            country: country,
            requestTimeout: requestTimeout,
            retryCount: retryCount
        ) { request in
            #expect(request.httpMethod == "GET")
            #expect(request.timeoutInterval == requestTimeout)

            let queryItems = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            #expect(queryItems.first(where: { $0.name == "bundleId" })?.value == bundleId)
            #expect(queryItems.first(where: { $0.name == "country" })?.value == country?.uppercased())

            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, Data(payload.utf8))
        }
    }

    private func makeProviderWithHandler(
        bundleId: String,
        installedVersion: String,
        country: String?,
        requestTimeout: TimeInterval = 15,
        retryCount: Int = 0,
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> AppStoreProvider {
        MockURLProtocol.requestHandler = handler

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        return AppStoreProvider(
            urlSession: session,
            decoder: JSONDecoder(),
            bundleId: bundleId,
            installedAppVersion: installedVersion,
            country: country,
            requestTimeout: requestTimeout,
            retryCount: retryCount,
            appId: ""
        )
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("requestHandler not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
