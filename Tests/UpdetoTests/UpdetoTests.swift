import XCTest

@testable import Updeto

#if canImport(Combine)
import Combine
#endif

final class UpdetoTests: XCTestCase {
    var result: AppStoreLookupResult?

    override func tearDownWithError() throws {
        result = nil
    }

    func testAppIsUpToDateAndWithoutErrorsOnLookup() throws {
        // Given
        let updeto = UpdetoMock(bundleId: "com.example.app", installedAppVersion: "1.0.0", responseType: .withResults)

        // When
        if #available(iOS 13.0, *) {
            updeto.isAppUpdated()
                .compactMap { $0 }
                .assign(to: \.result, on: self)
                .cancel()
        } else {
            updeto.isAppUpdated { lookupResult in
                self.result = lookupResult
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        let unwrappedResult = try XCTUnwrap(result)
        let appStoreURL = try XCTUnwrap(updeto.appstoreURL)
        XCTAssertEqual(unwrappedResult, .updated)
        XCTAssertEqual(appStoreURL.absoluteString, "itms-apps://apple.com/app/id123456789")
    }
    
    func testAppIsNotUpDateAndWithoutErrorsOnLookup() throws {
        // Given
        let updeto = UpdetoMock(bundleId: "com.example.app", installedAppVersion: "0.0.1", responseType: .withResults)

        // When
        if #available(iOS 13.0, *) {
            updeto.isAppUpdated()
                .compactMap { $0 }
                .assign(to: \.result, on: self)
                .cancel()
        } else {
            updeto.isAppUpdated { lookupResult in
                self.result = lookupResult
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        let unwrappedResult = try XCTUnwrap(result)
        let appStoreURL = try XCTUnwrap(updeto.appstoreURL)
        XCTAssertEqual(unwrappedResult, .outdated)
        XCTAssertEqual(appStoreURL.absoluteString, "itms-apps://apple.com/app/id123456789")
    }
    
    func testLookupHaveNoResults() throws {
        // Given
        let updeto = UpdetoMock(bundleId: "com.example.app", installedAppVersion: "0.0.1", responseType: .noResults)

        // When
        if #available(iOS 13.0, *) {
            updeto.isAppUpdated()
                .compactMap { $0 }
                .assign(to: \.result, on: self)
                .cancel()
        } else {
            updeto.isAppUpdated { lookupResult in
                self.result = lookupResult
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        let unwrappedResult = try XCTUnwrap(result)
        XCTAssertEqual(unwrappedResult, .noResults)
        XCTAssertNil(updeto.appstoreURL)
    }

    func testLookupUsingTesflightWithHigherVersionNumber() throws {
        // Given
        let updeto = UpdetoMock(bundleId: "com.example.app", installedAppVersion: "2.0.0", responseType: .withResults)

        // When
        if #available(iOS 13.0, *) {
            updeto.isAppUpdated()
                .compactMap { $0 }
                .assign(to: \.result, on: self)
                .cancel()
        } else {
            updeto.isAppUpdated { lookupResult in
                self.result = lookupResult
            }
        }

        _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 0.2)

        //Then
        let unwrappedResult = try XCTUnwrap(result)
        XCTAssertEqual(unwrappedResult, .developmentOrBeta)
        XCTAssertNotNil(updeto.appstoreURL)
    }
}
