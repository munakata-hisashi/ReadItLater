# Repository Guidelines

## Project Structure & Module Organization
ReadItLater is an iOS app built with SwiftUI and SwiftData. Core source lives under `ReadItLater/` and is organized by layers: `ReadItLater/Domain` (value objects and model helpers), `ReadItLater/Presentation` (view models), and `ReadItLater/View` (SwiftUI views). SwiftData migration logic is in `ReadItLater/Migration`, and assets live in `ReadItLater/Assets.xcassets`. Tests are split into unit tests in `ReadItLaterTests/` and UI tests in `ReadItLaterUITests/`. The Share extension code resides in `ShareExtension/`.

## Build, Test, and Development Commands
Use mise tasks for consistent output:
- `mise run buildformat` (alias `mise run b`) builds with `xcbeautify` formatting.
- `mise run testformat` (alias `mise run t`) runs all tests with formatted logs.
- `mise run unit` (alias `mise run u`) runs unit tests only.
Direct commands are also available, e.g. `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build`.

## Coding Style & Naming Conventions
Follow standard Swift conventions: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and functions. Keep file and type names aligned (e.g., `BookmarkURL.swift` defines `BookmarkURL`). SwiftData schema versions live in `ReadItLater/Migration/VersionedSchema.swift` and should be incremented via new schema types (e.g., `AppV3Schema`) rather than edited in place. No automatic formatter or linter is configured, so keep diffs tidy and consistent.

## Testing Guidelines
Testing uses XCTest. Unit tests live under `ReadItLaterTests/` and UI tests under `ReadItLaterUITests/`. Follow the existing naming pattern for test methods, e.g., `func test_空URL_作成失敗()` in `ReadItLaterTests/BookmarkCreationTests.swift`. Run all tests with `mise run testformat` or target-specific tests via `xcodebuild ... -only-testing:ReadItLaterTests`.

## Commit & Pull Request Guidelines
Commit messages should be in Japanese and follow a conventional-commit style. Use a short summary line and add bullet points for details. PRs should clearly describe behavior changes, link relevant issues or docs in `docs/`, and include screenshots for UI changes.

## Security & Configuration Tips
CloudKit is enabled via `ReadItLater/ReadItLater.entitlements` with container `iCloud.munakata-hisashi.ReadItLater`. When adjusting entitlements or CloudKit behavior, validate the simulator build first and avoid committing device-specific provisioning changes from Xcode.
