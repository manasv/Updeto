import Foundation
#if canImport(Combine)
import Combine
#endif

/// Default provider for App Store update checks (iOS, iPadOS, macOS, tvOS).
///
/// This provider uses the iTunes Lookup API to check for updates on the App Store.
public final class AppStoreProvider: UpdateProvider {
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    /// The bundle identifier of the app being checked.
    public let bundleId: String
    /// The currently installed version of the app.
    public let installedAppVersion: String
    /// The App Store app ID, if available.
    public var appId: String
    /// The App Store URL for the app, if available.
    public var appstoreURL: URL? {
        appId.isEmpty ? nil : URL(string: "itms-apps://apple.com/app/id\(appId)")
    }

    #if canImport(UIKit)
    /// Shared instance of `AppStoreProvider`.
    public static var shared = AppStoreProvider()
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
        bundleId: String = Bundle.main.bundleIdentifier!,
        installedAppVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!,
        appId: String = ""
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.bundleId = bundleId
        self.installedAppVersion = installedAppVersion
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
        appId: String = ""
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.bundleId = bundleId
        self.installedAppVersion = installedAppVersion
        self.appId = appId
    }
    #endif

    private var lookupRequest: URLRequest {
        let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    /// Checks if the app is updated using Combine.
    ///
    /// - Returns: A publisher emitting the result of the update check as `AppStoreLookupResult`.
    /// - Note: Available on macOS 12.0+, iOS 15.0+, tvOS 15.0+.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never> {
        urlSession
            .dataTaskPublisher(for: lookupRequest)
            .map { $0.data }
            .decode(type: AppStoreLookup.self, decoder: decoder)
            .map {
                guard !$0.results.isEmpty, let result = $0.results.first else {
                    return .noResults
                }
                self.appId = result.appId
                return self.compareVersions(result.version, self.installedAppVersion).appstoreLookupResult
            }
            .replaceError(with: .noResults)
            .eraseToAnyPublisher()
    }

    /// Checks if the app is updated using a completion handler.
    ///
    /// - Parameter completion: Closure called with the result of the update check as `AppStoreLookupResult`.
    public func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        urlSession
            .dataTask(with: lookupRequest) { data, _, _ in
                guard let data = data,
                    let lookup = try? self.decoder.decode(AppStoreLookup.self, from: data)
                else {
                    return
                }
                if !lookup.results.isEmpty, let appStore = lookup.results.first {
                    self.appId = appStore.appId
                    DispatchQueue.main.async {
                        completion(
                            self.compareVersions(appStore.version, self.installedAppVersion).appstoreLookupResult
                        )
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.noResults)
                    }
                }
            }.resume()
    }

    private func compareVersions(_ appstoreVersion: String, _ installedVersion: String) -> ComparisonResult {
        let versionDelimiter = "."
        var firstVersionComponents = appstoreVersion.components(separatedBy: versionDelimiter)
        var secondVersionComponents = installedVersion.components(separatedBy: versionDelimiter)
        let versionDiff = firstVersionComponents.count - secondVersionComponents.count
        if versionDiff == 0 {
            return appstoreVersion.compare(installedVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(versionDiff))
            if versionDiff > 0 {
                secondVersionComponents.append(contentsOf: zeros)
            } else {
                firstVersionComponents.append(contentsOf: zeros)
            }
            return firstVersionComponents.joined(separator: versionDelimiter)
                .compare(
                    secondVersionComponents.joined(separator: versionDelimiter),
                    options: .numeric
                )
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension AppStoreProvider: AsyncUpdateProvider {
    /// Checks if the app is updated using async/await.
    ///
    /// - Returns: The result of the update check as `AppStoreLookupResult`.
    public func isAppUpdated() async -> AppStoreLookupResult {
        do {
            let (data, _) = try await urlSession.data(for: lookupRequest)
            let lookup = try decoder.decode(AppStoreLookup.self, from: data)
            if !lookup.results.isEmpty, let result = lookup.results.first {
                self.appId = result.appId
                return self.compareVersions(result.version, self.installedAppVersion).appstoreLookupResult
            } else {
                return .noResults
            }
        } catch {
            return .noResults
        }
    }
}
