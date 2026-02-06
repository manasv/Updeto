import Foundation

/// The result of an App Store lookup and version comparison.
public enum AppStoreLookupResult: Equatable, Sendable, CustomStringConvertible {
    /// The app is currently updated.
    case updated
    /// The app is currently outdated.
    case outdated
    /// The installed version is higher than the latest on the App Store (e.g., development or beta build).
    case developmentOrBeta
    /// The bundleId query returned no results.
    case noResults

    /// A human-readable description of the lookup result.
    public var description: String {
        switch self {
        case .updated:
            return "The app is currently the latest version"
        case .outdated:
            return "The app has an update available"
        case .developmentOrBeta:
            return "The app version is either from a development or beta build."
        case .noResults:
            return "The query produced no results, please check the BundleID provided is correct."
        }
    }
}

/// Maps a ComparisonResult to an AppStoreLookupResult.
extension ComparisonResult {
    var appStoreLookupResult: AppStoreLookupResult {
        switch self {
        case .orderedSame:
            return .updated
        case .orderedDescending:
            return .outdated
        case .orderedAscending:
            return .developmentOrBeta
        }
    }
}
