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
import Models.AppStoreLookupResult
import Providers.UpdateProvider
import Providers.AppStoreProvider

// MARK: - Updeto (Facade)

/// Updeto is the main entry point for checking app updates using a pluggable provider system.
///
/// By default, it uses the App Store provider, but you can inject any custom provider conforming to `UpdateProvider`.
public final class Updeto: UpdateProvider {
    private let provider: UpdateProvider

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
    public init(provider: UpdateProvider = AppStoreProvider()) {
        self.provider = provider
    }

    /// Checks if the app is updated using Combine.
    ///
    /// - Returns: A publisher emitting the result of the update check as `AppStoreLookupResult`.
    /// - Note: Available on macOS 12.0+, iOS 15.0+, tvOS 15.0+.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
    public func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never> {
        provider.isAppUpdated()
    }

    /// Checks if the app is updated using a completion handler.
    ///
    /// - Parameter completion: Closure called with the result of the update check as `AppStoreLookupResult`.
    public func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        provider.isAppUpdated(completion: completion)
    }
}
