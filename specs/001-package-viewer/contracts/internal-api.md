# Internal API Contracts: macOS Package Viewer

**Feature**: 001-package-viewer
**Date**: 2026-01-19
**Purpose**: Define internal service contracts for package data retrieval

## Overview

This document defines the internal API contracts between the application layers. Since this is a native macOS app with no external API, these contracts define the protocols and interfaces between SwiftUI views, view models, and services.

## Architecture Layers

```
┌─────────────────────────────────────┐
│         SwiftUI Views               │  (UI Layer)
├─────────────────────────────────────┤
│         ViewModels                  │  (Presentation Layer)
├─────────────────────────────────────┤
│         Services                    │  (Business Logic Layer)
├─────────────────────────────────────┤
│    ShellCommandService              │  (System Integration Layer)
└─────────────────────────────────────┘
```

## Service Contracts

### PackageRepository Protocol

Defines the interface for fetching packages from any package manager.

**Protocol Definition**:

```swift
protocol PackageRepository {
    /// Fetches all packages from the package manager
    /// - Returns: Array of Package objects
    /// - Throws: PackageError if command fails or parsing fails
    func fetchPackages() async throws -> [Package]

    /// Checks if the package manager is available on the system
    /// - Returns: true if package manager is installed
    func isAvailable() async -> Bool
}
```

**Implementations**:
- `NpmPackageService`: Implements PackageRepository for npm
- `HomebrewPackageService`: Implements PackageRepository for Homebrew
- `PipPackageService`: Implements PackageRepository for pip

### ShellCommandService Contract

Defines the interface for executing shell commands and capturing output.

**Protocol Definition**:

```swift
protocol ShellCommandService {
    /// Executes a shell command and returns stdout
    /// - Parameters:
    ///   - command: Command executable (e.g., "npm", "brew")
    ///   - arguments: Command arguments (e.g., ["list", "--json"])
    ///   - timeout: Maximum time to wait (default: 10 seconds)
    /// - Returns: Command output as String
    /// - Throws: CommandError if command fails or times out
    @discardableResult
    func execute(
        command: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> String
}
```

**Error Types**:

```swift
enum CommandError: LocalizedError {
    case notFound(String)              // Command not on PATH
    case timeout(String)               // Execution exceeded timeout
    case failed(Int, String)           // Non-zero exit code
    case invalidOutput(String)         // Output cannot be decoded
}
```

## Service-Specific Contracts

### NpmPackageService

**Command**:
```bash
npm list -g --depth=0 --json
```

**Expected Output Format**:
```json
{
  "dependencies": {
    "package-name": {
      "version": "1.2.3"
    }
  }
}
```

**Parsing Rules**:
- Extract top-level dependencies (ignore nested)
- Map `version` from output
- Fetch size via: `du -sh $(npm prefix -g)/lib/node_modules/<package>/`
- Fetch date via: `stat -f "%Sm" $(npm prefix -g)/lib/node_modules/<package>/`
- Fetch description via: `npm view <package> description` (may skip for performance)

**Post-Processing**:
- Combine metadata from multiple commands
- Handle missing metadata gracefully (set to nil)

### HomebrewPackageService

**Command**:
```bash
brew info --json=v2 --all
```

**Expected Output Format**:
```json
{
  "formulae": [
    {
      "name": "git",
      "installed": [
        {
          "version": "2.43.0",
          "time": 1705037800
        }
      ],
      "desc": "Distributed version control system"
    }
  ]
}
```

**Parsing Rules**:
- Filter to only installed formulae (`installed` array is non-empty)
- Extract `name`, `version` (from first installed), `desc` (description)
- Extract `time` (installation timestamp)
- Size: Use brew info output or calculate via `du -sh /usr/local/Cellar/<name>/`

**Post-Processing**:
- Convert Unix timestamp to Date
- Use latest installed version if multiple

### PipPackageService

**Command**:
```bash
pip list --format=json
```

**Expected Output Format**:
```json
[
  {
    "name": "package-name",
    "version": "1.2.3"
  }
]
```

**Parsing Rules**:
- Extract all packages from array
- Map `name` and `version`
- Get site-packages path: `python -m site --user-site`
- Fetch size via: `du -sh <site-packages>/<package_name>/`
- Fetch date via: `stat -f "%Sm" <site-packages>/<package_name>/`

**Post-Processing**:
- Convert pip package names (use underscores, not hyphens)

## ViewModel Contracts

### PackageListViewModel

**Published Properties** (Observable Object):

```swift
@Published var packages: [Package] = []
@Published var filteredPackages: [Package] = []
@Published var searchQuery: String = ""
@Published var isLoading: Bool = false
@Published var error: PackageError?
```

**Public Methods**:

```swift
func loadPackages() async
func search(_ query: String)
func clearSearch()
func retry()
```

**Behavioral Contract**:

| Method | Precondition | Postcondition | Side Effects |
|--------|--------------|---------------|--------------|
| `loadPackages()` | None | `packages` contains all packages OR `error` is set | Sets `isLoading = true` during execution |
| `search(_:)` | None | `filteredPackages` contains matching packages | Updates `searchQuery` |
| `clearSearch()` | None | `filteredPackages` == `packages` | Sets `searchQuery = ""` |
| `retry()` | `error != nil` | `error = nil`, calls `loadPackages()` | Same as `loadPackages()` |

## View Contracts

### ContentView (Main Tab View)

**Responsibilities**:
- Display TabView with 3 tabs (npm, Homebrew, pip)
- Each tab contains a PackageListView
- Handle tab switching

**Props**: None (self-contained)

**Events**: None (delegates to child views)

### PackageListView

**Responsibilities**:
- Display loading spinner when `isLoading`
- Display error message when `error != nil`
- Display list of packages when loaded
- Display empty state when `packages.isEmpty`

**Props**:
- `viewModel: PackageListViewModel`

**Events**: None (handles search internally)

### PackageRowView

**Responsibilities**:
- Display single package in list
- Show name, size, description, date

**Props**:
- `package: Package`

**Events**: None (display-only)

### EmptyStateView

**Responsibilities**:
- Display friendly message when no packages found
- Show icon and text

**Props**:
- `message: String`
- `icon: String?` (optional system image name)

**Events**: None

### SearchBar

**Responsibilities**:
- Capture user search input
- Debounce input (300ms)
- Call `viewModel.search()`

**Props**:
- `viewModel: PackageListViewModel`

**Events**: Text binding updates `searchQuery`

## Data Flow Contracts

### Load Package Flow

```
User Action (Tab Switch or App Launch)
    ↓
ContentView (TabView selection changes)
    ↓
PackageListView.onAppear
    ↓
PackageListViewModel.loadPackages()
    ↓
PackageService.fetchPackages()
    ↓
ShellCommandService.execute()
    ↓
[Parse Output] → [Package]
    ↓
Update packages (published property)
    ↓
SwiftUI re-renders PackageListView
```

### Search Flow

```
User types in SearchBar
    ↓
SearchBar text binding
    ↓ (debounced 300ms)
PackageListViewModel.search()
    ↓
Filter packages array
    ↓
Update filteredPackages (published property)
    ↓
SwiftUI re-renders List
```

### Error Handling Flow

```
PackageService.fetchPackages() throws
    ↓
Catch error in PackageListViewModel.loadPackages()
    ↓
Map to PackageError
    ↓
Set error property (published)
    ↓
SwiftUI shows error view
    ↓
User clicks Retry
    ↓
PackageListViewModel.retry()
    ↓ (clears error)
Call loadPackages() again
```

## Performance Contracts

### Response Time Requirements

| Operation | Target | Max Acceptable |
|-----------|--------|----------------|
| Initial package load | < 2s | 5s |
| Tab switch (cached) | < 0.1s | 0.5s |
| Search filter | < 0.05s | 0.5s |
| Shell command | < 5s | 10s |

### Caching Strategy

- **In-Memory**: Cache `packages` array per PackageListViewModel instance
- **Duration**: Application session (cleared on app quit)
- **Invalidation**: None (packages don't change during session)
- **Size**: ~500 KB for 1000 packages (acceptable)

## Testing Contracts

### Mock Implementations

For testing, services should use mock implementations:

```swift
class MockPackageService: PackageRepository {
    var mockPackages: [Package] = []
    var shouldFail: Bool = false

    func fetchPackages() async throws -> [Package] {
        if shouldFail {
            throw PackageError.notInstalled
        }
        return mockPackages
    }

    func isAvailable() async -> Bool {
        return !shouldFail
    }
}
```

### Test Doubles

- **ShellCommandService**: Mock to return predefined JSON strings
- **PackageService**: Mock to return predefined Package arrays
- **ViewModel**: Test with mocked services

## Thread Safety Contract

- All service methods are `async` and run on background queue
- UI updates must happen on main actor (SwiftUI handles this)
- Published properties trigger UI updates on main thread automatically

## Error Handling Contract

All errors must conform to `LocalizedError` and provide:
- `errorDescription`: User-friendly message
- `recoverySuggestion`: Actionable suggestion (when applicable)
- `isRetryable`: Boolean indicating if operation can be retried
