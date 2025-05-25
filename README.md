# Updeto

[![Swift Package Index](https://img.shields.io/badge/Swift%20Package%20Index-compatible-brightgreen.svg)](https://swiftpackageindex.com/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS-blue.svg)](https://swiftpackageindex.com/)
[![Swift](https://img.shields.io/badge/swift-5.7%2B-orange.svg)](https://swiftpackageindex.com/)

**Updeto** is a Swift library for checking if your app is up-to-date on the App Store. It uses a provider-based architecture, supporting Combine, async/await, and completion handler APIs.

## Features

- Check for updates using the App Store (iTunes Lookup API)
- Pluggable provider system (use your own server or logic)
- Supports Combine, async/await, and completion handlers
- Returns rich result types (`AppStoreLookupResult`)

## Installation

Add Updeto to your project using Swift Package Manager:

```swift
.package(url: "https://github.com/yourusername/Updeto.git", from: "1.0.0")
```

## Usage

### Basic Usage

```swift
import Updeto

let updeto = Updeto()

// Combine (iOS 15+, macOS 12+)
if #available(iOS 15.0, macOS 12.0, *) {
    let cancellable = updeto.isAppUpdated()
        .sink { result in
            print(result) // .updated, .outdated, .developmentOrBeta, .noResults
        }
}

// Completion Handler
updeto.isAppUpdated { result in
    print(result)
}

// Async/Await (iOS 15+, macOS 12+)
if #available(iOS 15.0, macOS 12.0, *) {
    Task {
        let result = await updeto.isAppUpdated()
        print(result)
    }
}
```

### Custom Provider

You can provide your own update logic by conforming to `UpdateProvider` or `AsyncUpdateProvider`:

```swift
class MyCustomProvider: UpdateProvider {
    // ...implement required properties and methods...
}

let updeto = Updeto(provider: MyCustomProvider())
```

### Result Types

`AppStoreLookupResult` can be:

- `.updated` – The app is up to date
- `.outdated` – An update is available
- `.developmentOrBeta` – Installed version is newer (e.g., beta)
- `.noResults` – No app found for the bundle ID

## API Reference

- `Updeto`: Main entry point, facade for update checking
- `AppStoreProvider`: Default provider using the App Store
- `UpdateProvider`: Protocol for custom providers
- `AsyncUpdateProvider`: Protocol for async/await support

## Example

```swift
let updeto = Updeto()
updeto.isAppUpdated { result in
    switch result {
    case .updated:
        print("App is up to date!")
    case .outdated:
        print("Update available!")
    case .developmentOrBeta:
        print("Running a development or beta version.")
    case .noResults:
        print("App not found on the App Store.")
    }
}
```

## License

MIT © 2025 Manuel Sánchez

