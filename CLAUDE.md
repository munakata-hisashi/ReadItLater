# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadItLater is an iOS app for bookmarking URLs with planned AI-powered content summarization and translation features. Built with SwiftUI and SwiftData, with CloudKit synchronization for cross-device access.

## Development Commands

### mise Tasks (Recommended)
The project uses [mise](https://mise.jdx.dev/) for task automation. All commands are defined in `mise.toml` as the Single Source of Truth for both local development and CI.

**Development tasks:**
- **Build with formatted output**: `mise run buildformat` or `mise run b`
- **Run all tests with formatted output**: `mise run testformat` or `mise run t`
- **Run unit tests only**: `mise run unit` or `mise run u`
- **Build (raw output)**: `mise run build`
- **Run tests (raw output)**: `mise run test`

**CI tasks (used by GitHub Actions):**
- **CI build**: `mise run ci-build`
- **CI test**: `mise run ci-test`

**Important notes:**
- Formatted build tasks use `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES`, which causes the build to fail if there are any warnings
- Test tasks use `build-for-testing` + `test-without-building` pattern for faster execution
- Parallel testing is disabled (`-parallel-testing-enabled NO`) to avoid race conditions
- CI tasks use `--renderer github-actions` for proper output formatting in GitHub Actions
- All tasks explicitly specify `OS=26.0.1` in the simulator destination for consistency

### Direct xcodebuild Commands
- **Build for Simulator**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build`
- **Build (Generic)**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater build` (may fail with provisioning issues on device)
- **Run All Tests**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test`
- **Run UI Tests**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test -only-testing:ReadItLaterUITests`
- **Run Unit Tests Only**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test -only-testing:ReadItLaterTests`

### Simulator Configuration
- **Target**: arm64-apple-ios26.0.1-simulator
- **Deployment Target**: iOS 26.0.1+
- **Default Simulator**: iPhone 16 (iOS 26.0.1)

### Build Notes
- Provisioning profile issues may occur when building for physical devices
- Use specific simulator destination for consistent builds
- The project includes CoreData SQL debugging enabled in the scheme (`-com.apple.CoreData.SQLDebug 1`)

## Architecture

### Data Models & Migration System
The app uses a versioned schema architecture for SwiftData migrations:

- **Current Schema**: `AppV2Schema` (version 2.0.0) in `Migration/VersionedSchema.swift`
  - `Bookmark`: Primary model with id, createdAt, url, title
  - `Item` model has been removed from active use
- **Legacy Schema**: `AppV1Schema` (version 1.0.0) maintained for migration history
  - Contains both `Item` and `Bookmark` models
- **Type Alias**: `Domain/BookmarkExtensions.swift` defines `typealias Bookmark = AppV2Schema.Bookmark`
- **Migration Plan**: `Migration/MigrationPlan.swift` contains `AppMigrationPlan`
  - Includes both `AppV1Schema` and `AppV2Schema`
  - Uses lightweight migration (empty stages array - SwiftData handles automatically)
- **Model Container**: Configured in `ReadItLaterApp.swift:14-51` with migration plan integration
  - Schema only includes `Bookmark.self`

When adding new models or modifying existing ones:
1. Create new versioned schema (e.g., `AppV3Schema`)
2. Update migration plan to include new schema in schemas array
3. Add migration stages if custom migration logic is needed (otherwise use empty array for lightweight migration)
4. Update type aliases to point to new schema version

### CloudKit Integration
- **Container ID**: `iCloud.munakata-hisashi.ReadItLater` (defined in entitlements)
- **Services**: CloudKit enabled in entitlements for data synchronization
- **Configuration**: ModelContainer configured for CloudKit sync in app initialization
- **Debugging**: Commented CloudKit schema initialization code available in `ReadItLaterApp.swift:22-46`

### Project Structure
```
ReadItLater/
├── Domain/              # Domain models and value objects
│   ├── BookmarkExtensions.swift  # Type alias and extensions
│   ├── BookmarkData.swift        # DTO for bookmark creation
│   ├── BookmarkCreation.swift    # Factory methods
│   ├── BookmarkURL.swift
│   └── BookmarkTitle.swift
├── Migration/           # SwiftData schema versioning
│   ├── VersionedSchema.swift
│   └── MigrationPlan.swift
├── Presentation/        # ViewModels and presentation logic
│   └── AddBookmarkViewModel.swift
└── View/               # SwiftUI views
    ├── ContentView.swift
    ├── BookmarkView.swift
    └── AddBookmarkSheet.swift
```

### UI Structure
- **Navigation**: Uses `NavigationSplitView` pattern with master-detail layout
- **ContentView**: Master list showing bookmarks with CRUD operations
- **BookmarkView**: Detail view for individual bookmark display
- **AddBookmarkSheet**: Modal sheet for adding new bookmarks
- **Extensions**: Safe accessors defined for optional properties (`safeTitle`, `maybeURL`) in `Domain/BookmarkExtensions.swift`

## Planned Features
Based on README.md, the app will expand to include:
- Web content summarization via server-side processing
- Translation services for saved content
- Safari share extension for URL capture
- Enhanced content viewing and management

## Development Notes
- App targets iOS with sandbox entitlements
- Remote notifications configured for background processing
- Test targets include both unit tests (`ReadItLaterTests`) and UI tests (`ReadItLaterUITests`)
- Preview configurations use in-memory model containers for SwiftUI previews

## Git Commit Guidelines
- **Language**: Write commit messages in Japanese
- **Format**: Follow conventional commit style with descriptive Japanese messages
- **Structure**:
  - Short summary line in Japanese
  - Detailed bullet points for changes
  - Include Claude Code attribution footer

## GitHub Operations Guidelines

### Tool Selection: GitHub MCP vs gh CLI

**Use `gh` CLI for write operations (preferred):**
- Creating/editing PRs: `gh pr create`, `gh pr edit`
- Creating/editing Issues: `gh issue create`, `gh issue edit`
- Adding comments: `gh pr comment`, `gh issue comment`
- Merging PRs: `gh pr merge`
- Requesting reviews: `gh pr review`

**Use GitHub MCP for read operations:**
- Fetching PR details: `mcp__github__pull_request_read`
- Searching issues/PRs: `mcp__github__search_issues`, `mcp__github__search_pull_requests`
- Getting commit info: `mcp__github__get_commit`, `mcp__github__list_commits`
- Searching code: `mcp__github__search_code`

**Rationale:**
- `gh` CLI uses user authentication with broader permissions
- GitHub MCP may encounter 403 errors on write operations due to PAT restrictions
- GitHub MCP returns structured JSON data, better for complex queries
- Always try `gh` first for write operations, fallback to MCP only if unavailable