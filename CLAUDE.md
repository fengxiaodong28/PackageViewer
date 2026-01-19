# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PackageViewer** is a macOS application that displays locally installed packages from npm, Homebrew, and pip. Built with Swift 5.9+ and SwiftUI, following MVVM architecture with a service layer pattern.

**Tech Stack**: Swift 5.9+, SwiftUI, Foundation - no external dependencies

## Commands

```bash
cd PackageViewer

swift build              # Debug build
swift build -c release   # Release build
swift run                # Run directly
swift package clean      # Clean build artifacts
./build-app.sh           # Build .app bundle to Desktop
```

## Architecture

### Project Structure

```
PackageViewer/
├── Package.swift                    # Swift package manifest
├── build-app.sh                     # Creates .app bundle
└── Sources/PackageViewer/
    ├── PackageViewer.swift          # @main App entry point
    ├── Models/
    │   ├── Package.swift            # Package data model
    │   ├── PackageManager.swift     # Enum: npm, homebrew, pip
    │   └── PackageRepository.swift  # Protocol + PackageError, CommandError
    ├── Services/
    │   ├── ShellCommandService.swift   # Shell execution with timeout
    │   ├── HomebrewPackageService.swift
    │   ├── NpmPackageService.swift
    │   └── PipPackageService.swift
    ├── ViewModels/
    │   └── PackageListViewModel.swift  # @MainActor, @Published state
    └── Views/
        ├── ContentView.swift        # TabView container
        ├── PackageListView.swift    # Main list with loading/error/empty states
        ├── SearchBar.swift          # Real-time filtering
        └── EmptyStateView.swift
```

### MVVM + Service Layer Pattern

**Models**: `Package` struct, `PackageManager` enum

**Repository Protocol** (`PackageRepository.swift:3-6`):
```swift
protocol PackageRepository {
    func fetchPackages() async throws -> [Package]
    func isAvailable() async -> Bool
}
```

Each package manager has a service conforming to this protocol. Services use `ShellCommandService` to execute commands with 30s timeout and custom PATH configuration.

**ViewModels**: `@MainActor` classes with `@Published` properties for SwiftUI state management. Handles async package fetching, search filtering, and error states.

**Views**: Stateless SwiftUI views. Use `@StateObject` for ViewModels. Classes (not structs) for complex views with state.

### Error Handling

Two error hierarchies in `PackageRepository.swift`:

- **PackageError**: `.notInstalled`, `.timeout`, `.commandFailed`, `.parseFailed`, `.unknown`
- **CommandError**: `.notFound`, `.timeout`, `.failed`, `.invalidOutput`

Both conform to `LocalizedError` with `errorDescription` and `recoverySuggestion`. PackageError has `isRetryable` property.

## Extending the System

### Adding a New Package Manager

1. Create `[Name]PackageService.swift` in `Services/`
2. Conform to `PackageRepository` protocol
3. Use `ShellCommandService()` instance for shell commands
4. Add case to `PackageManager` enum in `Models/PackageManager.swift`
5. Update `PackageListViewModel.init()` switch statement
6. Add tab to `ContentView` TabView
7. Add icon to `Assets.xcassets`

## UI Conventions

- All Views are `struct` following SwiftUI convention
- ViewModels use `@StateObject` in views for state preservation
- **Loading States**: Show ProgressView during async operations
- **Error States**: Display error message with retry button for retryable errors
- **Empty States**: Show guidance when no packages exist or search has no results
- **Search**: Real-time filtering in ViewModel, debounced (300ms) with task cancellation

## Code Style

- 4-space indentation
- PascalCase for types, camelCase for properties
- One type per file (filename = type name)
- Use `async/await` for concurrency
- `@MainActor` for ViewModels (ensures UI thread)
- Comprehensive error handling with specific error types

## App Icon Management

Icons are stored in `Sources/PackageViewer/Resources/Assets.xcassets/AppIcon.appiconset/` as individual PNG files:
- `icon_16x16.png`, `icon_32x32.png`, `icon_64x64.png`, `icon_128x128.png`, `icon_256x256.png`, `icon_512x512.png`, `icon_1024x1024.png`

**To update the app icon:**
1. Prepare a 1024x1024 PNG image
2. Generate all sizes: `sips -z [size] [size] source.png --out icon_[size]x[size].png`
3. Run `./build-app.sh` - it automatically creates `.icns` file and updates the app bundle
4. The script clears icon cache and restarts Dock automatically

## Shell Command Execution

`ShellCommandService` executes commands via `/bin/zsh -l` with environment setup:
- Sources `~/.zshrc`, `~/.zprofile`, and `~/.nvm/nvm.sh`
- Custom PATH: `/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/opt/node@18/bin`
- 30-second timeout default
- Returns stdout, throws `CommandError` on failure

## Search Implementation

Search is debounced in `SearchBar.swift` (300ms delay) with proper task cancellation:
- Previous search tasks are cancelled before starting new ones
- `packageCount` updates dynamically based on filtered results
- Case-insensitive search on package names only

## State Management

ViewModels use `@StateObject` in views to preserve state across tab switches:
- `hasLoadedOnce` flag prevents redundant package fetching
- Packages load only once per session unless `retry()` is called
- Search state persists when switching between tabs

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
