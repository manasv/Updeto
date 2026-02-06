# Storefront And Errors

Use `AppStoreProvider(country:)` when you need deterministic lookup behavior for a specific storefront.

```swift
import Updeto

let provider = AppStoreProvider(
    bundleId: "com.example.app",
    installedAppVersion: "1.0.0",
    country: "US"
)

let updeto = Updeto(provider: provider)
```

If you need detailed failures, use `isAppUpdatedResult` instead of `isAppUpdated`.

```swift
updeto.isAppUpdatedResult { result in
    switch result {
    case .success(let status):
        print(status)
    case .failure(let error):
        // UpdetoError.network, .badServerResponse, .decoding
        print(error)
    }
}
```
