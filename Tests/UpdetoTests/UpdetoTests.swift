import XCTest

@testable import Updeto

#if canImport(Combine)
import Combine
#endif

final class UpdetoTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    #if canImport(Combine)
    func testAppIsUpToDateAndWithoutErrorsOnLookup() {
        // Given
        let updeto = UpdetoMock(shouldFail: false, isUpdated: true)
        var isUpdated = false
        var lookupError: Error?
        var streamFinished = false

        // When
        updeto.isAppUpdated()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    lookupError = error
                case .finished:
                    streamFinished = true
                }
            } receiveValue: { value in
                isUpdated = value
            }.store(in: &cancellables)

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        XCTAssertTrue(isUpdated)
        XCTAssertNil(lookupError)
        XCTAssertTrue(streamFinished)
    }

    func testAppIsNotUpToDateAndWithoutErrorsOnLookup() {
        // Given
        let updeto = UpdetoMock(shouldFail: false, isUpdated: false)
        var isUpdated = false
        var lookupError: Error?
        var streamFinished = false

        // When
        updeto.isAppUpdated()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    lookupError = error
                case .finished:
                    streamFinished = true
                }
            } receiveValue: { value in
                isUpdated = value
            }.store(in: &cancellables)

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        // Then
        XCTAssertFalse(isUpdated)
        XCTAssertNil(lookupError)
        XCTAssertTrue(streamFinished)
    }

    func testLookupFailedWithoutResults() {
        // Given
        let updeto = UpdetoMock(shouldFail: true, isUpdated: false)
        var isUpdated = false
        var lookupError: Error?
        var streamFinished = false

        // When
        updeto.isAppUpdated()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    lookupError = error
                case .finished:
                    streamFinished = true
                }
            } receiveValue: { value in
                isUpdated = value
            }.store(in: &cancellables)

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        // Then
        XCTAssertFalse(isUpdated)
        XCTAssertNotNil(lookupError)
        XCTAssertFalse(streamFinished)
    }
    #endif

    func testAppIsUpToDateAndWithoutErrorsOnLookupWithCompletionBlock() {
        // Given
        let updeto = UpdetoMock(shouldFail: false, isUpdated: true)
        var isUpdated = false
        var lookupError: Error?

        // When
        updeto.isAppUpdated { result in
            switch result {
            case .success(let value):
                isUpdated = value
            case .failure(let error):
                lookupError = error
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        XCTAssertTrue(isUpdated)
        XCTAssertNil(lookupError)
    }

    func testAppIsNotUpToDateAndWithoutErrorsOnLookupWithCompletionBlock() {
        // Given
        let updeto = UpdetoMock(shouldFail: false, isUpdated: false)
        var isUpdated = false
        var lookupError: Error?

        // When
        updeto.isAppUpdated { result in
            switch result {
            case .success(let value):
                isUpdated = value
            case .failure(let error):
                lookupError = error
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        XCTAssertFalse(isUpdated)
        XCTAssertNil(lookupError)
    }

    func testLookupFailedWithoutResultsWithCompletionBlock() {
        // Given
        let updeto = UpdetoMock(shouldFail: true, isUpdated: false)
        var isUpdated = false
        var lookupError: Error?

        // When
        updeto.isAppUpdated { result in
            switch result {
            case .success(let value):
                isUpdated = value
            case .failure(let error):
                lookupError = error
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        XCTAssertFalse(isUpdated)
        XCTAssertNotNil(lookupError)
    }
}
