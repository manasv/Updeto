# Production Integration

This guide covers practical choices for shipping `Updeto` in production apps.

## Storefront Strategy

Use a fixed `country` when your release flow or analytics depend on one storefront.

```swift
let provider = AppStoreProvider(
    bundleId: "com.example.app",
    installedAppVersion: "1.0.0",
    country: "US"
)
```

Use the default locale-based storefront when users can be in many regions.

## Retry And Timeout

Tune request behavior based on your app startup and UX budget.

```swift
let provider = AppStoreProvider(
    bundleId: "com.example.app",
    installedAppVersion: "1.0.0",
    requestTimeout: 10,
    retryCount: 1
)
```

`retryCount` is applied after the initial request.

## Error Handling

Use `updateInfoResult` or `isAppUpdatedResult` when you need explicit failure handling.

```swift
updeto.updateInfoResult { result in
    switch result {
    case .success(let info):
        if info.isUpdateAvailable {
            // show update UI
        }
    case .failure(let error):
        // log or soft-fail (do not block app launch)
        print(error)
    }
}
```

## UX Recommendations

- Do not block app launch on update checks.
- Cache the latest successful result and refresh opportunistically.
- If update is optional, show non-blocking prompts.
- If update is required, gate only after you have a reliable backend policy source.

## Testing Strategy

- Keep deterministic unit tests with mocked URL loading.
- Add an opt-in live integration test in CI nightly to catch upstream API behavior changes.
- Use environment variables for live test bundle ID and storefront.
