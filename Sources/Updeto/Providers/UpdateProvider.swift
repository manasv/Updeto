import Foundation
#if canImport(Combine)
import Combine
#endif

/// Protocol for update providers (App Store, custom servers, etc.)
///
/// Adopt this protocol to provide custom update-checking logic for your own server or distribution system.
public protocol UpdateProvider {
    #if canImport(Combine)
    /// Checks if the app is updated using Combine.
    ///
    /// - Returns: A publisher emitting the result of the update check as `AppStoreLookupResult`.
    /// - Note: Available on macOS 12.0+, iOS 15.0+, tvOS 15.0+.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never>
    #endif

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

/// Optional protocol for providers that expose rich update metadata.
public protocol UpdateInfoProvider: UpdateProvider {
    /// Checks for updates and returns rich metadata.
    func updateInfo(completion: @escaping (AppStoreUpdateInfo) -> Void)

    #if canImport(Combine)
    /// Checks for updates and emits rich metadata.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    func updateInfo() -> AnyPublisher<AppStoreUpdateInfo, Never>
    #endif
}

/// Optional protocol for providers that support async rich update metadata.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public protocol AsyncUpdateInfoProvider: UpdateInfoProvider {
    /// Checks for updates and returns rich metadata.
    func updateInfo() async -> AppStoreUpdateInfo
}

/// Optional protocol for providers that expose explicit error information.
public protocol ErrorAwareUpdateProvider: UpdateProvider {
    /// Checks if the app is updated and returns a result with detailed errors.
    func isAppUpdatedResult(completion: @escaping (Result<AppStoreLookupResult, UpdetoError>) -> Void)

    #if canImport(Combine)
    /// Checks if the app is updated and emits detailed errors.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    func isAppUpdatedResult() -> AnyPublisher<AppStoreLookupResult, UpdetoError>
    #endif
}

/// Optional protocol for providers that expose rich update metadata with explicit errors.
public protocol ErrorAwareUpdateInfoProvider: UpdateInfoProvider {
    /// Checks for updates and returns rich metadata with detailed errors.
    func updateInfoResult(completion: @escaping (Result<AppStoreUpdateInfo, UpdetoError>) -> Void)

    #if canImport(Combine)
    /// Checks for updates and emits rich metadata with detailed errors.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    func updateInfoResult() -> AnyPublisher<AppStoreUpdateInfo, UpdetoError>
    #endif
}

/// Optional protocol for providers that support async/await with detailed errors.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public protocol AsyncErrorAwareUpdateProvider: ErrorAwareUpdateProvider {
    /// Checks if the app is updated and throws detailed errors.
    func isAppUpdatedResult() async throws -> AppStoreLookupResult
}

/// Optional protocol for providers that support async rich metadata with detailed errors.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public protocol AsyncErrorAwareUpdateInfoProvider: ErrorAwareUpdateInfoProvider {
    /// Checks for updates and throws rich metadata with detailed errors.
    func updateInfoResult() async throws -> AppStoreUpdateInfo
}
