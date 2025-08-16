# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadItLater is an iOS app for bookmarking URLs with planned AI-powered content summarization and translation features. Built with SwiftUI and SwiftData, with CloudKit synchronization for cross-device access.

## Development Commands

### Building and Running
- **Build for Simulator**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.1' build`
- **Build (Generic)**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater build` (may fail with provisioning issues on device)
- **Run All Tests**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.1' test`
- **Run UI Tests**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.1' test -only-testing:ReadItLaterUITests`
- **Run Unit Tests Only**: `xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.1' test -only-testing:ReadItLaterTests`

### Simulator Configuration
- **Target**: arm64-apple-ios18.1-simulator
- **Deployment Target**: iOS 18.1+
- **Default Simulator**: iPhone 15 (iOS 18.1)

### Build Notes
- Provisioning profile issues may occur when building for physical devices
- Use specific simulator destination for consistent builds
- The project includes CoreData SQL debugging enabled in the scheme (`-com.apple.CoreData.SQLDebug 1`)

## Architecture

### Data Models & Migration System
The app uses a versioned schema architecture for SwiftData migrations:

- **Current Models**: Defined in `VersionedSchema.swift` as part of `AppV1Schema`
  - `Item`: Legacy model with timestamp, URL, title
  - `Bookmark`: Primary model with creation date, URL, title
- **Type Aliases**: `Bookmark.swift` and `Item.swift` define type aliases pointing to current schema versions
- **Migration Plan**: `MigrationPlan.swift` contains `AppMigrationPlan` with schema versions and migration stages
- **Model Container**: Configured in `ReadItLaterApp.swift:14-51` with migration plan integration

When adding new models or modifying existing ones:
1. Create new versioned schema (e.g., `AppV2Schema`)
2. Update migration plan with new schema and migration stages
3. Update type aliases to point to new schema version

### CloudKit Integration
- **Container ID**: `iCloud.munakata-hisashi.ReadItLater` (defined in entitlements)
- **Services**: CloudKit enabled in entitlements for data synchronization
- **Configuration**: ModelContainer configured for CloudKit sync in app initialization
- **Debugging**: Commented CloudKit schema initialization code available in `ReadItLaterApp.swift:22-46`

### UI Structure
- **Navigation**: Uses `NavigationSplitView` pattern with master-detail layout
- **ContentView**: Master list showing bookmarks with CRUD operations
- **BookmarkView**: Detail view for individual bookmark display
- **Extensions**: Safe accessors defined for optional properties (`safeTitle`, `maybeURL`)

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