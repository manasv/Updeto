# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]
### Changed
- Modernized platform support declarations for SwiftPM (`iOS 15`, `macOS 12`, `tvOS 15`).
- Replaced crash-prone force-unwrapped defaults with safe fallback values.
- Updated App Store lookup request construction to use safe URL components and `GET`.
- Improved result-model API ergonomics with `Sendable` and `CustomStringConvertible`.
- Made public lookup response fields accessible to SDK consumers.
- Added optional storefront `country` support for App Store lookups.
- Added error-aware update APIs (`Result`, throwing async, and failing publisher) via `UpdetoError`.
- Added rich update metadata output via `AppStoreUpdateInfo` and `updateInfo` APIs.
- Added configurable request timeout and retry controls in `AppStoreProvider`.
- Added a DocC catalog with an SDK overview and usage article.
- Added a production integration DocC article and an opt-in live App Store integration test.
- Migrated test suite to Swift Testing (`import Testing`).
- Added CI workflow for PR/main build+test validation and a release workflow for version tags.

### Fixed
- Completion-based API now consistently returns `.noResults` on invalid payloads instead of silently returning.
- Replaced placeholder tests with behavioral tests covering version comparison and completion/async provider flows.

## [0.0.2] - 2021-05-31
### Changed
- Dropped boolean output to use fully enum based output, with these posible outcomes: `updated`, `outdated` and `noResults`

## [0.0.1] - 2021-05-29
Initial Release
