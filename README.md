# Updeto

### ✅ Update checker for iOS Apps

# Summary

Updeto is a simple package that will help you to check if the currently installed version is the same as the latest one available on App Store.

# Installation

`Updeto` is available via Swift Package Manager

Using `Xcode` go to `File -> Swift Packages -> Add Package Dependency` and enter `https://github.com/manasv/Updeto`

# Usage

The convenience API yet simple, has mainly two methods depending on your preference to retrieve the update status, either with Combine or via completion block.

If you are either on iOS / iPadOS, you will have access to a singleton that automatically retrieves the Bundle ID and App Version in your app.

```swift
Updeto.shared.isAppUpdated { result in
    switch result {
    case .success(let value):
        // Do something with the value
    case .failure(let error):
        // Do something with the error
    }
}
```

Also you can create your own Updeto instance from the provided inits, requiring you to provide `bundleId` and `currentAppVersion`, you can optionally provide `appId` if you already know the one for your app, or it will be written when the Appstore Lookup is made, so you can after that perform something with the URL like:

```swift
if let url = Updeto.shared.appstoreURL {
    UIApplication.shared.canOpenURL(url){
        UIApplication.shared.openURL(url)
    }
}
```

Or whatever you want to do with the URL.

# TODOs

- [ ]  Improve the way `appstoreURL` is used, as right now if it's not set, is only a nil value.
- [ ]  Any other functionality that can be useful with what's provided by the Appstore Lookup
- [ ]  Decent rework to improve unit testing

# Considerations

This is a undocumented API (or kinda API), so Apple may change it in any moment and the result may change, use it at your own risk, however I will try to maintain it as up to date as possible to bring the same functionality.

Hope you can find this useful, even if you can do what the library does without major effort, I aimed to bring it in a easy way for you.

# Contributing

1. Fork QGrid
2. Create your feature branch
3. Commit your changes, along with unit tests (Currently using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).)
4. Push to the branch
4. Create pull request

