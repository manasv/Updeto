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
