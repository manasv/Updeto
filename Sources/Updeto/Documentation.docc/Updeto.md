# ``Updeto``

Check whether your installed app version is up to date on the App Store.

## Overview

`Updeto` is a facade over `UpdateProvider`.

The default provider (`AppStoreProvider`) performs these steps:
1. Calls the Apple iTunes Lookup API with your app `bundleId`.
2. Optionally scopes lookup to a storefront country (for example `US`).
3. Compares the App Store version against the installed app version.
4. Returns an `AppStoreLookupResult`.

Use error-aware variants if you need to distinguish transport/decode/HTTP failures.

## Topics

### Essentials

- ``Updeto/init(provider:)``
- ``Updeto/isAppUpdated(completion:)``
- ``Updeto/updateInfo(completion:)``

### Error-Aware APIs

- ``Updeto/isAppUpdatedResult(completion:)``
- ``Updeto/updateInfoResult(completion:)``
- ``UpdetoError``

### Providers

- ``UpdateProvider``
- ``UpdateInfoProvider``
- ``ErrorAwareUpdateProvider``
- ``ErrorAwareUpdateInfoProvider``
- ``AsyncUpdateProvider``
- ``AsyncUpdateInfoProvider``
- ``AsyncErrorAwareUpdateProvider``
- ``AsyncErrorAwareUpdateInfoProvider``
- ``AppStoreProvider``

### Results

- ``AppStoreLookupResult``
- ``AppStoreUpdateInfo``
- ``AppStoreLookup``

### Articles

- <doc:StorefrontAndErrors>
- <doc:ProductionIntegration>
