/**
 *  Updeto
 *
 *  Copyright (c) 2025 Manuel Sánchez. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Updeto (Facade)

/// Updeto is the main entry point for checking app updates using a pluggable provider system.
///
/// By default, it uses the App Store provider, but you can inject any custom provider conforming to `UpdateProvider`.
public final class Updeto: UpdateProvider {
    private var provider: UpdateProvider

    /// The bundle identifier of the app being checked.
    public var bundleId: String { provider.bundleId }
    /// The currently installed version of the app.
    public var installedAppVersion: String { provider.installedAppVersion }
    /// The App Store app ID, if available.
    public var appId: String {
        get { provider.appId }
        set { provider.appId = newValue }
    }
    /// The App Store URL for the app, if available.
    public var appstoreURL: URL? { provider.appstoreURL }

    /// Creates an Updeto instance with the given update provider.
    /// - Parameter provider: The update provider to use. Defaults to `AppStoreProvider()`.
    public init(
        provider: UpdateProvider = AppStoreProvider(
            bundleId: Bundle.main.bundleIdentifier ?? "",
            installedAppVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        )
    ) {
        self.provider = provider
    }

    #if canImport(Combine)
    /// Checks if the app is updated using Combine.
    ///
    /// - Returns: A publisher emitting the result of the update check as `AppStoreLookupResult`.
    /// - Note: Available on macOS 12.0+, iOS 15.0+, tvOS 15.0+.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never> {
        provider.isAppUpdated()
    }
    #endif

    /// Checks if the app is updated using a completion handler.
    ///
    /// - Parameter completion: Closure called with the result of the update check as `AppStoreLookupResult`.
    public func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        provider.isAppUpdated(completion: completion)
    }

    /// Checks if the app is updated and returns a detailed result with possible errors.
    ///
    /// - Parameter completion: Closure called with either an update result or an `UpdetoError`.
    public func isAppUpdatedResult(completion: @escaping (Result<AppStoreLookupResult, UpdetoError>) -> Void) {
        if let errorAwareProvider = provider as? any ErrorAwareUpdateProvider {
            errorAwareProvider.isAppUpdatedResult(completion: completion)
            return
        }

        provider.isAppUpdated { result in
            completion(.success(result))
        }
    }

    /// Checks for updates and returns rich metadata.
    ///
    /// - Parameter completion: Closure called with `AppStoreUpdateInfo`.
    public func updateInfo(completion: @escaping (AppStoreUpdateInfo) -> Void) {
        if let infoProvider = provider as? any UpdateInfoProvider {
            infoProvider.updateInfo(completion: completion)
            return
        }

        provider.isAppUpdated { result in
            completion(
                AppStoreUpdateInfo(
                    result: result,
                    installedVersion: self.installedAppVersion,
                    storeVersion: nil,
                    appId: self.appId.isEmpty ? nil : self.appId,
                    appStoreURL: self.appstoreURL,
                    bundleId: self.bundleId,
                    country: nil
                )
            )
        }
    }

    /// Checks for updates and returns rich metadata with detailed errors.
    ///
    /// - Parameter completion: Closure called with either `AppStoreUpdateInfo` or an `UpdetoError`.
    public func updateInfoResult(completion: @escaping (Result<AppStoreUpdateInfo, UpdetoError>) -> Void) {
        if let errorAwareInfoProvider = provider as? any ErrorAwareUpdateInfoProvider {
            errorAwareInfoProvider.updateInfoResult(completion: completion)
            return
        }

        if let errorAwareProvider = provider as? any ErrorAwareUpdateProvider {
            errorAwareProvider.isAppUpdatedResult { result in
                completion(
                    result.map { status in
                        AppStoreUpdateInfo(
                            result: status,
                            installedVersion: self.installedAppVersion,
                            storeVersion: nil,
                            appId: self.appId.isEmpty ? nil : self.appId,
                            appStoreURL: self.appstoreURL,
                            bundleId: self.bundleId,
                            country: nil
                        )
                    }
                )
            }
            return
        }

        provider.isAppUpdated { result in
            completion(
                .success(
                    AppStoreUpdateInfo(
                        result: result,
                        installedVersion: self.installedAppVersion,
                        storeVersion: nil,
                        appId: self.appId.isEmpty ? nil : self.appId,
                        appStoreURL: self.appstoreURL,
                        bundleId: self.bundleId,
                        country: nil
                    )
                )
            )
        }
    }

    /// Checks if the app is updated using async/await.
    ///
    /// - Returns: The result of the update check as `AppStoreLookupResult`.
    /// - Throws: Any error thrown by the underlying provider.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdated() async -> AppStoreLookupResult {
        if let asyncProvider = provider as? (any AsyncUpdateProvider) {
            return await asyncProvider.isAppUpdated()
        } else {
            // Fallback to completion-based API if async is not implemented
            return await withCheckedContinuation { continuation in
                provider.isAppUpdated { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }

    /// Checks for updates and returns rich metadata using async/await.
    ///
    /// - Returns: `AppStoreUpdateInfo`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func updateInfo() async -> AppStoreUpdateInfo {
        if let asyncInfoProvider = provider as? (any AsyncUpdateInfoProvider) {
            return await asyncInfoProvider.updateInfo()
        }

        if let infoProvider = provider as? any UpdateInfoProvider {
            return await withCheckedContinuation { continuation in
                infoProvider.updateInfo { info in
                    continuation.resume(returning: info)
                }
            }
        }

        let result = await isAppUpdated()
        return AppStoreUpdateInfo(
            result: result,
            installedVersion: installedAppVersion,
            storeVersion: nil,
            appId: appId.isEmpty ? nil : appId,
            appStoreURL: appstoreURL,
            bundleId: bundleId,
            country: nil
        )
    }

    /// Checks if the app is updated and throws detailed errors when supported by the provider.
    ///
    /// - Returns: The result of the update check as `AppStoreLookupResult`.
    /// - Throws: An `UpdetoError` if the provider supports error-aware async lookups.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdatedResult() async throws -> AppStoreLookupResult {
        if let asyncErrorAwareProvider = provider as? (any AsyncErrorAwareUpdateProvider) {
            return try await asyncErrorAwareProvider.isAppUpdatedResult()
        }

        if let errorAwareProvider = provider as? any ErrorAwareUpdateProvider {
            return try await withCheckedThrowingContinuation { continuation in
                errorAwareProvider.isAppUpdatedResult { result in
                    continuation.resume(with: result)
                }
            }
        }

        return await withCheckedContinuation { continuation in
            provider.isAppUpdated { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Checks for updates and returns rich metadata with detailed errors using async/await.
    ///
    /// - Returns: `AppStoreUpdateInfo`.
    /// - Throws: `UpdetoError` when the provider supports error-aware lookups.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func updateInfoResult() async throws -> AppStoreUpdateInfo {
        if let asyncErrorAwareInfoProvider = provider as? (any AsyncErrorAwareUpdateInfoProvider) {
            return try await asyncErrorAwareInfoProvider.updateInfoResult()
        }

        if let errorAwareInfoProvider = provider as? any ErrorAwareUpdateInfoProvider {
            return try await withCheckedThrowingContinuation { continuation in
                errorAwareInfoProvider.updateInfoResult { result in
                    continuation.resume(with: result)
                }
            }
        }

        if let asyncInfoProvider = provider as? (any AsyncUpdateInfoProvider) {
            return await asyncInfoProvider.updateInfo()
        }

        if let infoProvider = provider as? any UpdateInfoProvider {
            return await withCheckedContinuation { continuation in
                infoProvider.updateInfo { info in
                    continuation.resume(returning: info)
                }
            }
        }

        let result = try await isAppUpdatedResult()
        return AppStoreUpdateInfo(
            result: result,
            installedVersion: installedAppVersion,
            storeVersion: nil,
            appId: appId.isEmpty ? nil : appId,
            appStoreURL: appstoreURL,
            bundleId: bundleId,
            country: nil
        )
    }

    #if canImport(Combine)
    /// Checks if the app is updated and emits detailed errors when supported by the provider.
    ///
    /// - Returns: A publisher emitting update results or `UpdetoError`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdatedResult() -> AnyPublisher<AppStoreLookupResult, UpdetoError> {
        if let errorAwareProvider = provider as? any ErrorAwareUpdateProvider {
            return errorAwareProvider.isAppUpdatedResult()
        }

        return provider.isAppUpdated()
            .setFailureType(to: UpdetoError.self)
            .eraseToAnyPublisher()
    }

    /// Checks for updates and emits rich metadata.
    ///
    /// - Returns: A publisher emitting `AppStoreUpdateInfo`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func updateInfo() -> AnyPublisher<AppStoreUpdateInfo, Never> {
        if let infoProvider = provider as? any UpdateInfoProvider {
            return infoProvider.updateInfo()
        }

        return provider.isAppUpdated()
            .map { result in
                AppStoreUpdateInfo(
                    result: result,
                    installedVersion: self.installedAppVersion,
                    storeVersion: nil,
                    appId: self.appId.isEmpty ? nil : self.appId,
                    appStoreURL: self.appstoreURL,
                    bundleId: self.bundleId,
                    country: nil
                )
            }
            .eraseToAnyPublisher()
    }

    /// Checks for updates and emits rich metadata with detailed errors.
    ///
    /// - Returns: A publisher emitting `AppStoreUpdateInfo` or `UpdetoError`.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func updateInfoResult() -> AnyPublisher<AppStoreUpdateInfo, UpdetoError> {
        if let errorAwareInfoProvider = provider as? any ErrorAwareUpdateInfoProvider {
            return errorAwareInfoProvider.updateInfoResult()
        }

        if let infoProvider = provider as? any UpdateInfoProvider {
            return infoProvider.updateInfo()
                .setFailureType(to: UpdetoError.self)
                .eraseToAnyPublisher()
        }

        return isAppUpdatedResult()
            .map { status in
                AppStoreUpdateInfo(
                    result: status,
                    installedVersion: self.installedAppVersion,
                    storeVersion: nil,
                    appId: self.appId.isEmpty ? nil : self.appId,
                    appStoreURL: self.appstoreURL,
                    bundleId: self.bundleId,
                    country: nil
                )
            }
            .eraseToAnyPublisher()
    }
    #endif
}
