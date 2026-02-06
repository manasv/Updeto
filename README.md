# Updeto

[![Swift Package Index](https://img.shields.io/badge/Swift%20Package%20Index-compatible-brightgreen.svg)](https://swiftpackageindex.com/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS-blue.svg)](https://swiftpackageindex.com/)
[![Swift](https://img.shields.io/badge/swift-5.10%2B-orange.svg)](https://swiftpackageindex.com/)

`Updeto` is a lightweight Swift SDK to check whether the currently installed app version is up to date on the App Store.

It exposes the same check in three styles:
- `async/await`
- `Combine`
- completion callback
- optional error-aware variants (`Result`/throwing/failing publisher)
- optional rich metadata output (`AppStoreUpdateInfo`)

## Why Use It

- No App Store scraping logic in your app code
- Consistent result model (`AppStoreLookupResult`)
- Provider architecture, so you can swap App Store checks for your own backend
- Storefront-aware lookup via optional `country` parameter
- Configurable `requestTimeout` and `retryCount`

## Requirements

- Swift 5.10+
- iOS 15+
- macOS 12+
- tvOS 15+

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/manasv/Updeto.git", from: "1.0.0")
```

## Quick Start

```swift
import Updeto

let updeto = Updeto()

updeto.isAppUpdated { result in
    switch result {
    case .updated:
        print("You're on the latest version.")
    case .outdated:
        print("An update is available.")
    case .developmentOrBeta:
        print("Installed version is newer than App Store (dev/beta).")
    case .noResults:
        print("No App Store match found for this bundle ID.")
    }
}
```

If you want to force a specific App Store storefront:

```swift
import Updeto

let provider = AppStoreProvider(
    bundleId: "com.example.app",
    installedAppVersion: "1.0.0",
    country: "US",
    requestTimeout: 10,
    retryCount: 1
)

let updeto = Updeto(provider: provider)
```

## How It Works

`Updeto` is a facade over a pluggable `UpdateProvider`.

Default flow:
1. `Updeto` uses `AppStoreProvider`.
2. `AppStoreProvider` builds a lookup request to Apple iTunes Lookup API using your `bundleId`.
3. The API response is decoded into `AppStoreLookup`.
4. App Store version is compared with installed version.
5. SDK returns one `AppStoreLookupResult`.

Version comparison behavior:
- `appStoreVersion == installedVersion` -> `.updated`
- `appStoreVersion > installedVersion` -> `.outdated`
- `appStoreVersion < installedVersion` -> `.developmentOrBeta`
- no decode/result -> `.noResults`

Storefront behavior:
- If `country` is set, lookup includes `country=<CODE>` (for example `US`).
- If `country` is `nil`, provider uses current locale region by default.

## API Usage

### Async/Await

```swift
import Updeto

let updeto = Updeto()

if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
    Task {
        let result = await updeto.isAppUpdated()
        print(result.description)
    }
}
```

### Combine

```swift
import Combine
import Updeto

let updeto = Updeto()
var cancellables = Set<AnyCancellable>()

if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
    updeto.isAppUpdated()
        .sink { result in
            print(result)
        }
        .store(in: &cancellables)
}
```

### Completion Callback

```swift
import Updeto

let updeto = Updeto()
updeto.isAppUpdated { result in
    print(result)
}
```

### Error-Aware APIs

Use these variants when you need to distinguish `network`, `decode`, and `HTTP` failures from `.noResults`.

```swift
import Updeto

let updeto = Updeto()

updeto.isAppUpdatedResult { result in
    switch result {
    case .success(let status):
        print(status)
    case .failure(let error):
        print(error)
    }
}
```

### Rich Metadata Output

Use `updateInfo` when you need more than enum-only status.

```swift
import Updeto

let updeto = Updeto()

updeto.updateInfo { info in
    print(info.result)             // .updated / .outdated / ...
    print(info.installedVersion)   // local version
    print(info.storeVersion ?? "-")
    print(info.appId ?? "-")
    print(info.country ?? "-")
}
```

```swift
import Updeto

let updeto = Updeto()

if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
    Task {
        do {
            let info = try await updeto.updateInfoResult()
            print(info.result)
            print(info.storeVersion ?? "-")
        } catch {
            print(error)
        }
    }
}
```

## Dependency Injection

Inject your own provider if your update source is not App Store.

```swift
import Combine
import Foundation
import Updeto

final class InternalReleaseProvider: UpdateProvider {
    let bundleId: String = "com.example.app"
    let installedAppVersion: String = "1.0.0"
    var appId: String = ""
    var appstoreURL: URL? { nil }

    func isAppUpdated(completion: @escaping (AppStoreLookupResult) -> Void) {
        completion(.updated)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    func isAppUpdated() -> AnyPublisher<AppStoreLookupResult, Never> {
        Just(.updated).eraseToAnyPublisher()
    }
}

let updeto = Updeto(provider: InternalReleaseProvider())
```

## Public Types

- `Updeto`: entry point used by apps
- `AppStoreProvider`: default implementation calling Apple lookup API
- `UpdateProvider`: protocol for custom providers
- `AsyncUpdateProvider`: optional async protocol for custom providers
- `AppStoreLookupResult`: enum output (`updated`, `outdated`, `developmentOrBeta`, `noResults`)
- `AppStoreUpdateInfo`: rich output with `result`, `installedVersion`, `storeVersion`, `appId`, `bundleId`, `country`
- `UpdetoError`: error output for error-aware APIs (`network`, `badServerResponse`, `decoding`)

## Notes

- `appstoreURL` becomes available when an App Store `appId` is resolved.
- `.noResults` can mean invalid bundle ID, network/decode failure, or no store match.
- Apple lookup availability depends on region/store state.

## Live Integration Test (Opt-in)

`Updeto` includes an opt-in live test (`Tests/UpdetoLiveIntegrationTests.swift`) for nightly CI checks.

```bash
UPDETO_RUN_LIVE_TESTS=1 \
UPDETO_LIVE_BUNDLE_ID=com.example.app \
UPDETO_LIVE_COUNTRY=US \
swift test
```

## License

MIT © 2025 Manuel Sánchez
