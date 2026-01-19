# AGENTS.md - Agentic Coding Guidelines

This file provides guidelines for AI agents working in this repository.

## Project Overview

**PackageViewer** is a macOS application that displays locally installed packages from npm, Homebrew, and pip. Built with Swift 5.9+ and SwiftUI, following MVVM architecture with a service layer pattern.

**Tech Stack**: Swift 5.9+, SwiftUI, Foundation - no external dependencies

## Build Commands

### PackageViewer App
```bash
cd PackageViewer
swift build              # Debug build
swift build -c release   # Release build
swift build --arch arm64 # Apple Silicon
swift build --arch x86_64 # Intel
./build-app.sh           # Build .app to Desktop
swift package clean      # Clean artifacts
swift run                # Run directly
```

### CLI Tool (root directory)
```bash
swift run PackageViewerCLI  # Run the CLI package detector
```

## Testing

**Note:** This project currently has no test suite. When adding tests:

```bash
# Run all tests
swift test

# Run a single test (filter by regex)
swift test --filter "PackageTests"

# Run tests with coverage
swift test --enable-code-coverage
```

## Code Style Guidelines

### General Principles
- Follow standard Swift conventions (Swift API Design Guidelines)
- Keep functions focused and single-purpose
- Use Swift 5.9+ features where appropriate (parameter packs, typed throws)
- One type per file (filename matches type name)

### Naming Conventions
- **Types/Classes/Structs/Enums:** PascalCase (e.g., `PackageListViewModel`)
- **Properties/Variables/Constants:** camelCase (e.g., `isLoading`, `filteredPackages`)
- **Functions/Methods:** camelCase, verb-first (e.g., `loadPackages()`, `clearSearch()`)
- **Acronyms:** Use consistent case based on position (e.g., `npmPackage`, `URL`)
- **Protocols:** Suffix with "Protocol" or describe capability (e.g., `PackageRepository`)

### Imports
- Import only what is needed
- System frameworks first, then third-party
- Group imports by framework with one blank line between groups
```swift
import Foundation
import SwiftUI
```

### Formatting
- Use 4 spaces for indentation (Xcode default)
- Opening braces on same line as declaration
- No trailing commas in arrays/dictionaries
- Max line length ~100 characters
- Use implicit returns in single-expression functions

### Types
- Use `struct` for value types (most models)
- Use `class` for reference types requiring inheritance or shared state
- Mark `@MainActor` on ViewModels and UI-related classes
- Use optionals (`?`) for potentially nil values, not sentinel values
- Use type inference when type is obvious

### Error Handling
- Define specific error types (enums conforming to `Error`)
- Conform to `LocalizedError` with `errorDescription` and `recoverySuggestion`
- Use `throw` for recoverable errors
- Use `try?` for ignore-on-failure scenarios
- Avoid `try!` except in tests or when failure is truly impossible

### Async/Await
- Prefer `async`/`await` over completion handlers
- Mark async functions explicitly
- Use `Task` for background work
- Use `@MainActor` to ensure UI updates on main thread
- Use `TaskGroup` for parallel processing

### SwiftUI
- Use `ObservableObject` with `@Published` for ViewModels
- Keep Views thin, ViewModels thin-to-medium, Models thin
- Use `some View` for return types
- Prefix View names with context (e.g., `PackageListView`, `EmptyStateView`)
- Use `class` for views with `@StateObject` ViewModel, otherwise `struct`

### File Organization
- One public type per file (unless closely related)
- Filename matches type name
- Group related types in subdirectories
- Resources (assets) in `Resources/` folder adjacent to Sources

### Access Control
- Use `private` by default
- `fileprivate` only when needed across extensions in same file
- `internal` (default) for package-internal APIs
- `public` only for APIs exposed to consumers

### Documentation
- Use /// for public API documentation
- Document non-obvious behavior
- Document thrown errors in function comments

## Architecture Patterns

### MVVM + Service Layer

**Models**: `Package` struct, `PackageManager` enum

**Repository Protocol** (`PackageRepository.swift:3-6`):
```swift
protocol PackageRepository {
    func fetchPackages() async throws -> [Package]
    func isAvailable() async -> Bool
}
```

Each package manager has a service conforming to this protocol. Services use `ShellCommandService` to execute commands with timeout and custom PATH configuration.

**ViewModels**: `@MainActor` classes with `@Published` properties for SwiftUI state management. Handles async package fetching, search filtering, and error states.

**Views**: Stateless SwiftUI views. Use `@StateObject` for ViewModels.

### Error Hierarchy

Two error hierarchies in `PackageRepository.swift`:

- **PackageError**: `.notInstalled`, `.timeout`, `.commandFailed`, `.parseFailed`, `.unknown`
- **CommandError**: `.notFound`, `.timeout`, `.failed`, `.invalidOutput`

Both conform to `LocalizedError` with `errorDescription` and `recoverySuggestion`. PackageError has `isRetryable` property.

### Adding a New Package Manager

1. Create `[Name]PackageService.swift` in `Services/`
2. Conform to `PackageRepository` protocol
3. Use `ShellCommandService.shared.execute()` for shell commands
4. Add case to `PackageManager` enum in `Models/PackageManager.swift`
5. Update `ContentView` TabView to include new tab
6. Add icon to `Assets.xcassets`
