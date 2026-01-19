# Quickstart Guide: macOS Package Viewer

**Feature**: 001-package-viewer
**Date**: 2026-01-19
**Purpose**: Get started with development and testing of the Package Viewer application

## Prerequisites

### Required Software

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.0+** (for SwiftUI and Swift 5.9+ support)
- **Git** (for version control)

### Package Managers (for testing)

The app requires at least one of these to be installed:
- **npm** (comes with Node.js)
- **Homebrew**
- **pip** (comes with Python)

**Check installations**:
```bash
which npm    # Should return path if installed
which brew   # Should return path if installed
which pip3   # Should return path if installed
```

## Project Setup

### 1. Clone and Navigate

```bash
cd ~/Desktop/spec-kit-study
git checkout 001-package-viewer
```

### 2. Create Xcode Project

Open **Xcode** and create a new project:

1. **File → New → Project**
2. Select **macOS → App**
3. Enter details:
   - **Product Name**: `PackageViewer`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
   - **Location**: `~/Desktop/spec-kit-study/PackageViewer/`
4. **Create**

### 3. Configure Project Settings

In Xcode project settings:

1. **General Tab**:
   - **Bundle Identifier**: `com.speckit.PackageViewer`
   - **Version**: `1.0`
   - **Build**: `1`

2. **Signing & Capabilities**:
   - **Team**: Select your development team
   - **Signing**: Automatically manage signing

3. **Deployment Target**:
   - **macOS**: `14.0`

### 4. Verify Build

```bash
cd PackageViewer
xcodebuild -scheme PackageViewer -configuration Debug build
```

Or press **⌘+B** in Xcode.

## Project Structure

Create the following directory structure:

```bash
cd PackageViewer
mkdir -p Models Views ViewModels Services Resources
```

Your structure should look like:

```
PackageViewer/
├── PackageViewerApp.swift
├── Models/
│   ├── Package.swift
│   ├── PackageManager.swift
│   └── PackageRepository.swift
├── Views/
│   ├── ContentView.swift
│   ├── PackageListView.swift
│   ├── PackageRowView.swift
│   ├── EmptyStateView.swift
│   └── SearchBar.swift
├── ViewModels/
│   └── PackageListViewModel.swift
├── Services/
│   ├── ShellCommandService.swift
│   ├── NpmPackageService.swift
│   ├── HomebrewPackageService.swift
│   └── PipPackageService.swift
└── Resources/
    ├── Assets.xcassets/
    └── Localizable.strings
```

## Implementation Order

Follow this order to build incrementally and test at each step:

### Phase 1: Core Models (30 minutes)

1. **Create Package.swift**
   - Define Package struct with all fields
   - Implement Identifiable protocol
   - Add validation logic

2. **Create PackageManager.swift**
   - Define enum with npm, homebrew, pip cases
   - Add display properties

3. **Create PackageRepository.swift**
   - Define protocol
   - Define PackageError enum

**Test**: Create a few test Package instances in preview.

### Phase 2: Shell Integration (1 hour)

4. **Create ShellCommandService.swift**
   - Implement Process/Pipe execution
   - Add timeout handling
   - Add error handling

**Test**: Execute simple commands like `echo "hello"` and verify output.

### Phase 3: Package Services (2 hours)

5. **Create NpmPackageService.swift**
   - Implement PackageRepository
   - Parse npm output
   - Handle missing npm gracefully

6. **Create HomebrewPackageService.swift**
   - Implement PackageRepository
   - Parse brew output
   - Handle missing brew gracefully

7. **Create PipPackageService.swift**
   - Implement PackageRepository
   - Parse pip output
   - Handle missing pip gracefully

**Test**: Run each service independently and print package lists.

### Phase 4: ViewModels (1 hour)

8. **Create PackageListViewModel.swift**
   - Implement @ObservableObject
   - Implement loadPackages() method
   - Implement search filtering
   - Add error handling

**Test**: Create preview with mocked data.

### Phase 5: Views (2 hours)

9. **Create ContentView.swift**
   - Implement TabView with 3 tabs
   - Embed PackageListView for each tab

10. **Create PackageListView.swift**
    - Implement List view
    - Handle loading/error/empty states
    - Integrate SearchBar

11. **Create PackageRowView.swift**
    - Display package info
    - Format size and date nicely

12. **Create EmptyStateView.swift**
    - Show friendly message
    - Add icon

13. **Create SearchBar.swift**
    - Capture user input
    - Implement debouncing

**Test**: Run app and verify all views render correctly.

### Phase 6: Integration & Polish (1 hour)

14. **Add Assets**
    - Add icons for each package manager
    - Add empty state illustrations

15. **Localization**
    - Add Localizable.strings
    - Externalize all user-facing text

16. **Performance Tuning**
    - Add background processing
    - Implement progressive loading
    - Add caching

**Test**: Run with 500+ packages and verify smooth scrolling.

## Development Workflow

### Running the App

In Xcode:
- Press **⌘+R** to run
- Select target device (My Mac)

### Debugging

- **Print logs**: Use `print()` or `NSLog()`
- **Breakpoints**: Click line number to set breakpoint
- **View Console**: ⌘+Shift+C

### Testing

Create test targets in Xcode:
1. **File → New → Target**
2. Select **Unit Testing Bundle**
3. Name: `PackageViewerTests`

Run tests: **⌘+U**

### Common Commands

```bash
# Build
xcodebuild -scheme PackageViewer build

# Run tests
xcodebuild test -scheme PackageViewer

# Clean build
xcodebuild clean -scheme PackageViewer
```

## Troubleshooting

### Issue: "Command not found" errors

**Cause**: Package manager not installed or not on PATH

**Solution**:
1. Install missing package manager:
   ```bash
   # npm
   brew install node

   # Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # pip
   brew install python3
   ```

2. Verify installation: `which <command>`

### Issue: Shell command times out

**Cause**: Package list too large or system slow

**Solution**: Increase timeout in ShellCommandService:
```swift
let timeout: TimeInterval = 30.0  // Increase from 10
```

### Issue: JSON parsing fails

**Cause**: Output format changed or malformed

**Solution**:
1. Print raw output to debug
2. Update parsing logic to handle edge cases
3. Add error recovery for partial data

### Issue: App won't build

**Cause**: Xcode version mismatch or syntax error

**Solution**:
1. Verify Xcode 15.0+ installed
2. Check Swift version in Build Settings
3. Review build log for specific errors

## Code Snippets

### Shell Command Execution

```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/bin/bash")
process.arguments = ["-c", "npm list -g --json"]

let pipe = Pipe()
process.standardOutput = pipe

try process.run()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8)
```

### Package Parsing (npm)

```swift
struct NpmOutput: Codable {
    let dependencies: [String: NpmPackage]
}

struct NpmPackage: Codable {
    let version: String
}
```

### Debounced Search

```swift
@Published var searchQuery: String = ""
private var debounceTask: Task<Void, Never>?

func search(_ query: String) {
    debounceTask?.cancel()
    debounceTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        filteredPackages = packages.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
```

## Next Steps

After completing the quickstart:

1. **Run on real system** with actual packages installed
2. **Test edge cases**: Missing managers, empty lists, 1000+ packages
3. **Add unit tests** for all services and view models
4. **Add UI tests** for key user flows
5. **Profile performance** using Instruments
6. **Polish UI**: Refine spacing, typography, colors

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [Process Class](https://developer.apple.com/documentation/foundation/process)
- [Xcode Help](https://help.apple.com/xcode/)
