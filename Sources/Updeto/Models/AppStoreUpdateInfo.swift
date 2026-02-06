import Foundation

/// Rich metadata returned from an App Store update check.
public struct AppStoreUpdateInfo: Equatable, Sendable {
    /// Final status of the version comparison.
    public let result: AppStoreLookupResult
    /// Version currently installed in the app.
    public let installedVersion: String
    /// Version currently available in the App Store, when present.
    public let storeVersion: String?
    /// App Store identifier, when present.
    public let appId: String?
    /// App Store deep link, when present.
    public let appStoreURL: URL?
    /// Bundle identifier used for lookup.
    public let bundleId: String
    /// Storefront country used for lookup, when present.
    public let country: String?

    /// Convenience flag for update prompts.
    public var isUpdateAvailable: Bool {
        result == .outdated
    }

    public init(
        result: AppStoreLookupResult,
        installedVersion: String,
        storeVersion: String?,
        appId: String?,
        appStoreURL: URL?,
        bundleId: String,
        country: String?
    ) {
        self.result = result
        self.installedVersion = installedVersion
        self.storeVersion = storeVersion
        self.appId = appId
        self.appStoreURL = appStoreURL
        self.bundleId = bundleId
        self.country = country
    }
}
