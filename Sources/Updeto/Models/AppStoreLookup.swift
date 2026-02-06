import Foundation

/// The response model for the iTunes Lookup API.
public struct AppStoreLookup: Decodable, Sendable {
    /// The number of results returned by the API.
    public let resultCount: Int
    /// The array of lookup results.
    public let results: [LookupResult]

    /// Represents a single app result from the iTunes Lookup API.
    public struct LookupResult: Decodable, Sendable {
        /// The version string of the app on the App Store.
        public let version: String
        /// The bundle identifier of the app.
        public let bundleId: String
        /// The App Store app ID.
        public let appId: String

        enum CodingKeys: String, CodingKey {
            case version, bundleId
            case appId = "trackId"
        }

        /// Decodes a LookupResult from the API response.
        /// - Parameter decoder: The decoder to use.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let intValue = try container.decode(Int.self, forKey: .appId)
            self.appId = String(intValue)
            self.bundleId = try container.decode(String.self, forKey: .bundleId)
            self.version = try container.decode(String.self, forKey: .version)
        }
    }
}
