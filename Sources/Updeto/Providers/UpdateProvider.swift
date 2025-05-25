import Foundation
#if canImport(Combine)
import Combine
#endif
import Models.AppStoreLookupResult

/// Protocol for update providers (App Store, custom servers, etc.)
///
/// Adopt this protocol to provide custom update-checking logic for your own server or distribution system.
public protocol UpdateProvider {
    /// Checks if the app is updated using Combine.
    ///
    /// - Returns: A publisher emitting the result of the update check as `AppStoreLookupResult`.
    /// - Note: Available on macOS 12.0+, iOS 15.0+, tvOS 15.0+.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never>

    /// Checks if the app is updated using a completion handler.
    ///
    /// - Parameter completion: Closure called with the result of the update check as `AppStoreLookupResult`.
    func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void)

    /// The bundle identifier of the app being checked.
    var bundleId: String { get }
    /// The currently installed version of the app.
    var installedAppVersion: String { get }
    /// The App Store app ID, if available.
    var appId: String { get set }
    /// The App Store URL for the app, if available.
    var appstoreURL: URL? { get }
}

/// Optional protocol for providers that support async/await.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public protocol AsyncUpdateProvider: UpdateProvider {
    /// Checks if the app is updated using async/await.
    ///
    /// - Returns: The result of the update check as `AppStoreLookupResult`.
    func isAppUpdated() async -> AppStoreLookupResult
}
