import Foundation

@testable import Updeto

#if canImport(Combine)
import Combine
#endif

final class UpdetoMock: UpdetoType {
    let bundleId: String
    let installedAppVersion: String
    let responseType: Mock

    var appId: String = ""
    var appstoreURL: URL? {
        appId.isEmpty ? nil : URL(string: "itms-apps://apple.com/app/id\(appId)")
    }

    init(
        bundleId: String,
        installedAppVersion: String,
        responseType: Mock
    ) {
        self.bundleId = bundleId
        self.installedAppVersion = installedAppVersion
        self.responseType = responseType
    }

    @available(iOS 13, *)
    func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never> {
        if let response = responseType.response.results.first {
            let result = response.version == installedAppVersion ? AppStoreLookupResult.updated : .outdated
            appId = response.appId
            return Just(result).eraseToAnyPublisher()
        } else {
            return Just(.noResults).eraseToAnyPublisher()
        }
    }

    func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        if let response = responseType.response.results.first {
            let result = response.version == installedAppVersion ? AppStoreLookupResult.updated : .outdated
            appId = response.appId
            completion(result)
        } else {
            completion(.noResults)
        }
    }
}

enum Mock {
    case withResults
    case noResults

    var data: Data {
        switch self {
        case .withResults:
            return """
                {
                  "resultCount": 1,
                  "results": [
                    {
                      "trackId": 123456789,
                      "bundleId": "com.example.app",
                      "version": "1.0.0"
                    }
                  ]
                }
                """.data(using: .utf8) ?? Data()
        case .noResults:
            return """
                {
                  "resultCount": 0,
                  "results": []
                }
                """.data(using: .utf8) ?? Data()
        }
    }

    var response: AppStoreLookup {
        do {
            return try JSONDecoder().decode(AppStoreLookup.self, from: self.data)
        } catch {
            return AppStoreLookup(resultCount: 0, results: [])
        }
    }
}
