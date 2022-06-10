/**
 *  Updeto
 *
 *  Copyright (c) 2021 Manuel Sánchez. Licensed under the MIT license, as follows:
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

// MARK: - UpdetoType Protocol Definition

protocol UpdetoType {
    @available(macOS 10.15, iOS 13.0, *)
    func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never>
    func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void)
    var bundleId: String { get }
    var currentAppVersion: String { get }
    var appId: String { get set }
    var appstoreURL: URL? { get }
}

// MARK: - Updeto

public final class Updeto: UpdetoType {
    // MARK: - Private Properties

    private let urlSession: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Protocol Properties
    var appId: String
    let bundleId: String
    let currentAppVersion: String

    // MARK: - Singleton

    #if canImport(UIKit)
    public static var shared = Updeto()
    #endif

    // MARK: - Initializers
    //Finds the current app bundle ID for the App Store which is stored in a variable, bundleID, for later use in the API call
    //Finds the current app version from the local app information which is later compared to the version fetched by the API call to see if the app is outdated
    #if canImport(UIKit)
    public init(
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        bundleId: String = Bundle.main.bundleIdentifier!,
        currentAppVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!,
        appId: String = ""
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.bundleId = bundleId
        self.currentAppVersion = currentAppVersion
        self.appId = appId
    }
    #else
    public init(
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        bundleId: String,
        currentAppVersion: String,
        appId: String = ""
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.bundleId = bundleId
        self.currentAppVersion = currentAppVersion
        self.appId = appId

    }
    #endif

    // MARK: - Computed Properties

    /// URLRequest to verify latest App Store version for the Bundle ID
    private var lookupRequest: URLRequest {
        let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        return request
    }

    // MARK: - Public Properties

    /// App Store URL that can be opened to see the Store Page for the App
    public var appstoreURL: URL? {
        appId.isEmpty ? nil : URL(string: "itms-apps://apple.com/app/id\(appId)")
    }

    // MARK: - Public Methods

    /// Retrieves metadata from the App Store for the Bundle ID provided and compares versions to determine if an update is needed.
    /// - returns: A publisher with `AppStoreLookupResult`  with the status of the lookup operation.
    @available(macOS 10.15, iOS 13.0, *)
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

                return result.version == self.currentAppVersion ? .updated : .outdated
            }
            .replaceError(with: .noResults)
            .eraseToAnyPublisher()
    }

    /// Retrieves metadata from the App Store for the Bundle ID provided and compares versions to determine if an update is needed.
    /// - parameter completion: The completion block to be called on the main thread when the validation has finished.
    /// - returns: `AppStoreLookupResult` with the status of the lookup operation.
    public func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        urlSession
            .dataTask(with: lookupRequest) { data, _, _ in
                guard let data = data,
                    let lookup = try? self.decoder.decode(AppStoreLookup.self, from: data)
                else {
                    return
                }

                if !lookup.results.isEmpty, let result = lookup.results.first {
                    self.appId = result.appId

                    DispatchQueue.main.async {
                        completion(
                            result.version == self.currentAppVersion ? .updated : .outdated
                        )
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.noResults)
                    }
                }
            }.resume()
    }
}

// MARK: - AppStoreLookup

struct AppStoreLookup: Decodable {
    let resultCount: Int
    let results: [LookupResult]

    struct LookupResult: Decodable {
        let version: String
        let bundleId: String
        let appId: String

        enum CodingKeys: String, CodingKey {
            case version, bundleId
            case appId = "trackId"
        }

        init(
            from decoder: Decoder
        ) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let intValue = try container.decode(Int.self, forKey: .appId)

            self.appId = String(intValue)
            self.bundleId = try container.decode(String.self, forKey: .bundleId)
            self.version = try container.decode(String.self, forKey: .version)
        }
    }
}

// MARK: - AppstoreLookupResult

public enum AppStoreLookupResult: Equatable {
    case updated
    case outdated
    case noResults

    /// Lookup Result description.
    var description: String {
        switch self {
        case .noResults:
            return "The query produced no results, please check the BundleID provided is correct."
        case .updated:
            return "The app is currently the latest version"
        case .outdated:
            return "The app has an update available"
        }
    }

    public static func == (lhs: AppStoreLookupResult, rhs: AppStoreLookupResult) -> Bool {
        lhs.description == rhs.description
    }
}
