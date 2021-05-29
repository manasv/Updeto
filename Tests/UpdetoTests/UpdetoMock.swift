import Foundation

@testable import Updeto

#if canImport(Combine)
import Combine
#endif

struct UpdetoMock: UpdetoType {
    let shouldFail: Bool
    let isUpdated: Bool

    init(
        shouldFail: Bool = false,
        isUpdated: Bool = false
    ) {
        self.shouldFail = shouldFail
        self.isUpdated = isUpdated
    }

    func isAppUpdated() -> AnyPublisher<Bool, Error> {
        if shouldFail {
            return Fail(error: LookupError.noResults).eraseToAnyPublisher()
        } else {
            return Just(isUpdated)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    func isAppUpdated(completion: @escaping (Result<Bool, Error>) -> Void) {
        if shouldFail {
            completion(.failure(LookupError.noResults))
        } else {
            completion(.success(isUpdated))
        }
    }

    var appstoreURL: URL?
}
