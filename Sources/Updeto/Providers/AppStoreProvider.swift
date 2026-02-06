import Foundation
#if canImport(Combine)
import Combine
#endif

/// Default provider for App Store update checks (iOS, iPadOS, macOS, tvOS).
///
/// This provider uses the iTunes Lookup API to check for updates on the App Store.
public final class AppStoreProvider: UpdateProvider {
    private enum Constants {
        static let shortVersionKey = "CFBundleShortVersionString"
    }

    private let urlSession: URLSession
    private let decoder: JSONDecoder

    /// The bundle identifier of the app being checked.
    public let bundleId: String
    /// The currently installed version of the app.
    public let installedAppVersion: String
    /// The App Store app ID, if available.
    public var appId: String
    /// Optional storefront country code used for lookup requests (e.g. `US`, `ES`).
    public var country: String?
    /// Request timeout in seconds.
    public var requestTimeout: TimeInterval
    /// Number of retry attempts applied after the initial request.
    public var retryCount: Int
    /// The App Store URL for the app, if available.
    public var appstoreURL: URL? {
        appId.isEmpty ? nil : URL(string: "itms-apps://apple.com/app/id\(appId)")
    }

    #if canImport(UIKit)
    /// Shared instance of `AppStoreProvider`.
    public static let shared = AppStoreProvider()
    #endif

    #if canImport(UIKit)
    /// Creates an AppStoreProvider instance.
    /// - Parameters:
    ///   - urlSession: The URLSession to use for network requests. Defaults to `.shared`.
    ///   - decoder: The JSONDecoder to use for decoding responses. Defaults to `JSONDecoder()`.
    ///   - bundleId: The bundle identifier of the app. Defaults to the main bundle identifier.
    ///   - installedAppVersion: The installed version of the app. Defaults to the main bundle version.
    ///   - appId: The App Store app ID. Defaults to an empty string.
    public init(
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        bundleId: String = Bundle.main.bundleIdentifier ?? "",
        installedAppVersion: String = Bundle.main.object(forInfoDictionaryKey: Constants.shortVersionKey) as? String ?? "0",
        country: String? = AppStoreProvider.defaultCountryCode,
        requestTimeout: TimeInterval = 15,
        retryCount: Int = 0,
        appId: String = ""
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.bundleId = bundleId
        self.installedAppVersion = installedAppVersion
        self.country = Self.normalizedCountryCode(country)
        self.requestTimeout = max(1, requestTimeout)
        self.retryCount = max(0, retryCount)
        self.appId = appId
    }
    #else
    /// Creates an AppStoreProvider instance.
    /// - Parameters:
    ///   - urlSession: The URLSession to use for network requests. Defaults to `.shared`.
    ///   - decoder: The JSONDecoder to use for decoding responses. Defaults to `JSONDecoder()`.
    ///   - bundleId: The bundle identifier of the app. Defaults to the main bundle identifier.
    ///   - installedAppVersion: The installed version of the app. Defaults to the main bundle version.
    ///   - appId: The App Store app ID. Defaults to an empty string.
    public init(
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        bundleId: String,
        installedAppVersion: String,
        country: String? = AppStoreProvider.defaultCountryCode,
        requestTimeout: TimeInterval = 15,
        retryCount: Int = 0,
        appId: String = ""
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.bundleId = bundleId
        self.installedAppVersion = installedAppVersion
        self.country = Self.normalizedCountryCode(country)
        self.requestTimeout = max(1, requestTimeout)
        self.retryCount = max(0, retryCount)
        self.appId = appId
    }
    #endif

    public static var defaultCountryCode: String? {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            return Locale.current.region?.identifier
        }
        return Locale.current.regionCode
    }

    private static func normalizedCountryCode(_ country: String?) -> String? {
        guard let trimmed = country?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed.uppercased()
    }

    private var lookupRequest: URLRequest {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var queryItems = [URLQueryItem(name: "bundleId", value: bundleId)]
        if let country = Self.normalizedCountryCode(country) {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        components?.queryItems = queryItems
        let url = components?.url ?? URL(string: "https://itunes.apple.com/lookup")!
        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.httpMethod = "GET"
        return request
    }

    /// Checks if the app is updated using Combine.
    ///
    /// - Returns: A publisher emitting the result of the update check as `AppStoreLookupResult`.
    /// - Note: Available on macOS 12.0+, iOS 15.0+, tvOS 15.0+.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never> {
        updateInfoResult()
            .map(\.result)
            .replaceError(with: .noResults)
            .eraseToAnyPublisher()
    }

    /// Checks if the app is updated using Combine and emits detailed errors.
    ///
    /// - Returns: A publisher emitting the result of the update check or an `UpdetoError`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdatedResult() -> AnyPublisher<AppStoreLookupResult, UpdetoError> {
        updateInfoResult()
            .map(\.result)
            .eraseToAnyPublisher()
    }

    /// Checks for updates using Combine and emits rich metadata.
    ///
    /// - Returns: A publisher emitting `AppStoreUpdateInfo`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func updateInfo() -> AnyPublisher<AppStoreUpdateInfo, Never> {
        updateInfoResult()
            .replaceError(with: noResultsInfo)
            .eraseToAnyPublisher()
    }

    /// Checks for updates using Combine and emits rich metadata with detailed errors.
    ///
    /// - Returns: A publisher emitting `AppStoreUpdateInfo` or an `UpdetoError`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func updateInfoResult() -> AnyPublisher<AppStoreUpdateInfo, UpdetoError> {
        return urlSession
            .dataTaskPublisher(for: lookupRequest)
            .retry(retryCount)
            .mapError { error -> UpdetoError in
                .network(error)
            }
            .tryMap { payload -> Data in
                guard let http = payload.response as? HTTPURLResponse else {
                    throw UpdetoError.badServerResponse(statusCode: -1)
                }
                guard 200..<300 ~= http.statusCode else {
                    throw UpdetoError.badServerResponse(statusCode: http.statusCode)
                }
                return payload.data
            }
            .mapError { error -> UpdetoError in
                if let updetoError = error as? UpdetoError {
                    return updetoError
                }
                return .network(URLError(.unknown))
            }
            .tryMap { data in
                try self.parseLookupInfo(from: data)
            }
            .mapError { error -> UpdetoError in
                if let updetoError = error as? UpdetoError {
                    return updetoError
                }
                return .decoding
            }
            .eraseToAnyPublisher()
    }

    /// Checks if the app is updated using a completion handler.
    ///
    /// - Parameter completion: Closure called with the result of the update check as `AppStoreLookupResult`.
    public func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        updateInfoResult { result in
            completion((try? result.get().result) ?? .noResults)
        }
    }

    /// Checks if the app is updated using a completion handler and returns detailed errors.
    ///
    /// - Parameter completion: Closure called with either an update result or an `UpdetoError`.
    public func isAppUpdatedResult(completion: @escaping (Result<AppStoreLookupResult, UpdetoError>) -> Void) {
        updateInfoResult(completion: { result in
            completion(result.map(\.result))
        })
    }

    /// Checks for updates using a completion handler and returns rich metadata.
    ///
    /// - Parameter completion: Closure called with `AppStoreUpdateInfo`.
    public func updateInfo(completion: @escaping (AppStoreUpdateInfo) -> Void) {
        updateInfoResult { result in
            completion((try? result.get()) ?? self.noResultsInfo)
        }
    }

    /// Checks for updates using a completion handler and returns rich metadata with detailed errors.
    ///
    /// - Parameter completion: Closure called with either `AppStoreUpdateInfo` or an `UpdetoError`.
    public func updateInfoResult(completion: @escaping (Result<AppStoreUpdateInfo, UpdetoError>) -> Void) {
        executeLookup(attempt: 0, completion: completion)
    }

    private func executeLookup(
        attempt: Int,
        completion: @escaping (Result<AppStoreUpdateInfo, UpdetoError>) -> Void
    ) {
        urlSession
            .dataTask(with: lookupRequest) { data, response, error in
                if let urlError = error as? URLError {
                    let failure: Result<AppStoreUpdateInfo, UpdetoError> = .failure(.network(urlError))
                    if self.shouldRetry(after: .network(urlError), attempt: attempt) {
                        self.executeLookup(attempt: attempt + 1, completion: completion)
                        return
                    }
                    DispatchQueue.main.async {
                        completion(failure)
                    }
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(.badServerResponse(statusCode: -1)))
                    }
                    return
                }

                guard 200..<300 ~= http.statusCode else {
                    let serverError = UpdetoError.badServerResponse(statusCode: http.statusCode)
                    if self.shouldRetry(after: serverError, attempt: attempt) {
                        self.executeLookup(attempt: attempt + 1, completion: completion)
                        return
                    }
                    DispatchQueue.main.async {
                        completion(.failure(serverError))
                    }
                    return
                }

                guard let data else {
                    DispatchQueue.main.async {
                        completion(.failure(.network(URLError(.badServerResponse))))
                    }
                    return
                }

                do {
                    let result = try self.parseLookupInfo(from: data)
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                } catch let error as UpdetoError {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(.decoding))
                    }
                }
            }.resume()
    }

    private var noResultsInfo: AppStoreUpdateInfo {
        AppStoreUpdateInfo(
            result: .noResults,
            installedVersion: installedAppVersion,
            storeVersion: nil,
            appId: nil,
            appStoreURL: nil,
            bundleId: bundleId,
            country: Self.normalizedCountryCode(country)
        )
    }

    private func parseLookupInfo(from data: Data) throws -> AppStoreUpdateInfo {
        let lookup: AppStoreLookup
        do {
            lookup = try decoder.decode(AppStoreLookup.self, from: data)
        } catch {
            throw UpdetoError.decoding
        }

        guard let appStore = lookup.results.first else {
            return noResultsInfo
        }

        appId = appStore.appId
        let result = compareVersions(appStore.version, installedAppVersion).appStoreLookupResult
        return AppStoreUpdateInfo(
            result: result,
            installedVersion: installedAppVersion,
            storeVersion: appStore.version,
            appId: appStore.appId,
            appStoreURL: URL(string: "itms-apps://apple.com/app/id\(appStore.appId)"),
            bundleId: bundleId,
            country: Self.normalizedCountryCode(country)
        )
    }

    private func shouldRetry(after error: UpdetoError, attempt: Int) -> Bool {
        guard attempt < retryCount else { return false }

        switch error {
        case .network:
            return true
        case .badServerResponse(let statusCode):
            return statusCode >= 500
        case .decoding:
            return false
        }
    }

    /**
     Compares two version strings to determine their order.

     This method compares the version of the app available on the App Store
     (`appstoreVersion`) with the currently installed version (`installedVersion`).
     It handles cases where the versions have different numbers of components
     by padding the shorter version with zeros.

     - Parameters:
       - appstoreVersion: The version string from the App Store (e.g., "1.2.3").
       - installedVersion: The version string of the installed app (e.g., "1.2").

     - Returns: A `ComparisonResult` indicating the order of the versions:
       - `.orderedAscending`: The installed version is newer (e.g., development or beta).
       - `.orderedSame`: The versions are the same.
       - `.orderedDescending`: The App Store version is newer (e.g., an update is available).
     */
    func compareVersions(_ appstoreVersion: String, _ installedVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        // Split version strings into components
        var appstoreComponents = appstoreVersion.components(separatedBy: versionDelimiter)
        var installedComponents = installedVersion.components(separatedBy: versionDelimiter)

        // Equalize the number of components by padding with zeros
        let componentDifference = appstoreComponents.count - installedComponents.count
        if componentDifference > 0 {
            installedComponents.append(contentsOf: Array(repeating: "0", count: componentDifference))
        } else if componentDifference < 0 {
            appstoreComponents.append(contentsOf: Array(repeating: "0", count: -componentDifference))
        }

        // Compare the normalized version strings
        let normalizedAppstoreVersion = appstoreComponents.joined(separator: versionDelimiter)
        let normalizedInstalledVersion = installedComponents.joined(separator: versionDelimiter)

        return normalizedAppstoreVersion.compare(normalizedInstalledVersion, options: .numeric)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension AppStoreProvider: AsyncUpdateProvider {
    /// Checks if the app is updated using async/await.
    ///
    /// - Returns: The result of the update check as `AppStoreLookupResult`.
    public func isAppUpdated() async -> AppStoreLookupResult {
        (try? await updateInfoResult())?.result ?? .noResults
    }
}

extension AppStoreProvider: UpdateInfoProvider {}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension AppStoreProvider: AsyncUpdateInfoProvider {
    /// Checks for updates using async/await and returns rich metadata.
    ///
    /// - Returns: `AppStoreUpdateInfo`.
    public func updateInfo() async -> AppStoreUpdateInfo {
        (try? await updateInfoResult()) ?? noResultsInfo
    }
}

extension AppStoreProvider: ErrorAwareUpdateProvider {}
extension AppStoreProvider: ErrorAwareUpdateInfoProvider {}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension AppStoreProvider: AsyncErrorAwareUpdateProvider {
    /// Checks if the app is updated using async/await and throws detailed errors.
    ///
    /// - Returns: The result of the update check as `AppStoreLookupResult`.
    /// - Throws: An `UpdetoError` when the request fails.
    public func isAppUpdatedResult() async throws -> AppStoreLookupResult {
        let info = try await updateInfoResult()
        return info.result
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension AppStoreProvider: AsyncErrorAwareUpdateInfoProvider {
    /// Checks for updates using async/await and throws rich metadata with detailed errors.
    ///
    /// - Returns: `AppStoreUpdateInfo`.
    /// - Throws: An `UpdetoError` when the request fails.
    public func updateInfoResult() async throws -> AppStoreUpdateInfo {
        var attempt = 0

        while true {
            do {
                let (data, response) = try await urlSession.data(for: lookupRequest)
                guard let http = response as? HTTPURLResponse else {
                    throw UpdetoError.badServerResponse(statusCode: -1)
                }
                guard 200..<300 ~= http.statusCode else {
                    throw UpdetoError.badServerResponse(statusCode: http.statusCode)
                }
                return try parseLookupInfo(from: data)
            } catch let error as UpdetoError {
                if shouldRetry(after: error, attempt: attempt) {
                    attempt += 1
                    continue
                }
                throw error
            } catch let error as URLError {
                let updetoError = UpdetoError.network(error)
                if shouldRetry(after: updetoError, attempt: attempt) {
                    attempt += 1
                    continue
                }
                throw updetoError
            } catch {
                throw UpdetoError.decoding
            }
        }
    }
}
