# Repository Guidelines

## Project Structure & Module Organization
ReadItLater is an iOS app built with SwiftUI and SwiftData. Core source lives under `ReadItLater/` and is organized by layers: `ReadItLater/Domain`, `ReadItLater/Presentation`, and `ReadItLater/View`. SwiftData migration logic is in `ReadItLater/Migration`, and assets live in `ReadItLater/Assets.xcassets`. Tests are in `ReadItLaterTests/` (unit) and `ReadItLaterUITests/` (UI). The Share extension code resides in `ShareExtension/`.

## Build, Test, and Development Commands
Use mise tasks for consistent output:
- `mise run buildformat` (alias `mise run b`) builds with `xcbeautify` formatting.
- `mise run testformat` (alias `mise run t`) runs all tests with formatted logs.
- `mise run unit` (alias `mise run u`) runs unit tests only.
Direct commands are also available, e.g. `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build`.

## Coding Style & Naming Conventions
Follow standard Swift conventions: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and functions. Keep file and type names aligned (e.g., `BookmarkURL.swift` defines `BookmarkURL`). SwiftData schema versions live in `ReadItLater/Migration/VersionedSchema.swift` and should be incremented via new schema types rather than edited in place. No automatic formatter or linter is configured, so keep diffs tidy and consistent.
For new bookmark creation or URL validation, prefer the `Bookmark.create(from:title:)` factory in `ReadItLater/Domain/BookmarkCreation.swift` instead of constructing models directly.

## Architecture & Data
SwiftData uses a versioned schema plan in `ReadItLater/Migration/MigrationPlan.swift`. The current schema is `AppV3Schema`, which defines `Inbox`, `Bookmark`, and `Archive` models; update the migration plan when introducing a new schema. Shared persistence is created by `ReadItLater/ModelContainerFactory.swift` using the App Group container `group.munakata-hisashi.ReadItLater`, and previews use the in-memory container. The Share Extension uses the same shared container to persist incoming URLs.

## Testing Guidelines
Testing uses XCTest. Unit tests live under `ReadItLaterTests/` and UI tests under `ReadItLaterUITests/`. Follow the existing naming pattern for test methods, e.g., `func test_空URL_作成失敗()` in `ReadItLaterTests/BookmarkCreationTests.swift`. Run all tests with `mise run testformat` or target-specific tests via `xcodebuild ... -only-testing:ReadItLaterTests`.

## Commit & Pull Request Guidelines
Commit messages should be in Japanese and follow a conventional-commit style. Use a short summary line and add bullet points for details. PRs should clearly describe behavior changes, link relevant issues or docs in `docs/`, and include screenshots for UI changes.

## Security & Configuration Tips
CloudKit is enabled via `ReadItLater/ReadItLater.entitlements` with container `iCloud.munakata-hisashi.ReadItLater`. When adjusting entitlements or CloudKit behavior, validate the simulator build first and avoid committing device-specific provisioning changes from Xcode.
