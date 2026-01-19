# Implementation Plan: macOS Package Viewer

**Branch**: `001-package-viewer` | **Date**: 2026-01-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-package-viewer/spec.md`
**Technical Approach**: Native macOS application built with Swift and SwiftUI, leveraging system APIs and package manager CLI tools

## Summary

Build a native macOS application that allows users to view locally installed packages from npm, Homebrew, and pip package managers. The app provides a tabbed interface to switch between package types, displays package information (name, size, description, installation date), and includes real-time search filtering. Technical approach uses Swift/SwiftUI for the UI with system shell commands to retrieve package information.

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 15.0+ required)
**Primary Dependencies**: SwiftUI (system framework), Foundation (system framework) - minimal external dependencies
**Storage**: N/A (read-only access to package manager databases via CLI)
**Testing**: XCTest framework (built into Xcode)
**Target Platform**: macOS 14.0+ (Sonoma and later)
**Project Type**: Single native macOS application
**Performance Goals**:
- Package list loading: < 5 seconds (SC-001)
- Tab switching: < 1 second (SC-002)
- Search filtering: < 0.5 seconds per keystroke (SC-003)
- Display 500+ packages without lag (SC-004)
**Constraints**:
- Must run on macOS only (FR-011)
- Must use graphical UI, not CLI (FR-012)
- Minimal external dependencies (per user input)
- Handle missing package managers gracefully (FR-015)
**Scale/Scope**:
- Support 3 package manager types: npm, Homebrew, pip
- Handle up to 1000+ packages per manager
- Single-screen application with ~3 main views (list views for each package type)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Assessment

**I. Code Quality Excellence** - ✅ PASS
- Swift's strong type system supports type safety principle
- SwiftUI encourages single-responsibility components
- Swift's error handling (Result types, do-catch) aligns with error handling requirements

**II. Testing Standards** - ✅ PASS
- XCTest provides native testing framework
- XCTest supports fast, independent unit tests
- Swift's type system enables compile-time safety

**III. User Experience Consistency** - ✅ PASS
- SwiftUI provides native macOS UI patterns (tabs, lists, search)
- System-standard loading indicators and error states available
- Accessibility built into SwiftUI components
- Native macOS look and feel ensures consistency

**IV. Performance Requirements** - ⚠️ NEEDS VALIDATION
- Success criteria defined (< 5s load, < 1s tab switch, < 0.5s search)
- Must validate in Phase 0 that shell command execution can meet these targets
- May need background processing/caching for large package lists

**V. Development Discipline** - ✅ PASS
- Git for version control
- Xcode for development and testing
- Native build system (no complex build configuration needed)

### Gating Decision

**STATUS**: ✅ **PROCEED TO PHASE 0** with validation requirement:
- Phase 0 research MUST verify that shell command performance meets success criteria
- If shell commands are too slow, MUST identify alternative approaches (caching, background processing, etc.)

---

### Post-Design Re-Evaluation

After completing Phase 0 research and Phase 1 design, the constitution check is re-evaluated:

**I. Code Quality Excellence** - ✅ PASS (validated)
- Swift's strong type system ensures type safety
- MVVM architecture promotes single responsibility
- Swift's Result types and async/await provide clean error handling
- Code structure follows dependency inversion (PackageRepository protocol)

**II. Testing Standards** - ✅ PASS (validated)
- XCTest provides comprehensive testing capabilities
- Protocol-based design enables easy mocking (PackageRepository, ShellCommandService)
- Test independence achievable through dependency injection
- Unit tests can run in < 100ms per test (fast feedback principle)

**III. User Experience Consistency** - ✅ PASS (validated)
- SwiftUI TabView provides standard navigation pattern
- Native macOS controls (List, SearchBar, loading states)
- Accessibility built into all SwiftUI components
- Native look and feel ensures consistency with macOS ecosystem

**IV. Performance Requirements** - ✅ PASS (validated through research)

Research findings confirm all performance targets achievable:

| Metric | Target | Research Finding | Status |
|--------|--------|-------------------|--------|
| Package load | < 5s | < 2s with background loading | ✅ EXCEEDS |
| Tab switch | < 1s | < 0.1s with caching | ✅ EXCEEDS |
| Search filter | < 0.5s | < 0.05s in-memory | ✅ EXCEEDS |
| 500+ packages | Smooth | SwiftUI List lazy loading | ✅ PASS |

**Optimization strategies identified**:
- Progressive rendering (names first, metadata in background)
- In-memory caching (instant tab switches)
- Debounced search (300ms)
- Parallel size calculations (DispatchQueue)

**V. Development Discipline** - ✅ PASS (validated)
- Xcode provides integrated Git workflow
- Native build system (no complex dependencies)
- XCTest integrated into Xcode for test-driven development
- Swift Package Manager for dependency management (if needed)

### Final Constitution Compliance

**STATUS**: ✅ **ALL PRINCIPLES SATISFIED**

No constitutional violations identified. No complexity tracking required.

The design:
- Uses minimal dependencies (only system frameworks)
- Follows Swift/SwiftUI best practices
- Implements comprehensive error handling
- Provides excellent performance characteristics
- Enables thorough testing through protocol-based design

## Project Structure

### Documentation (this feature)

```text
specs/001-package-viewer/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
PackageViewer/
├── PackageViewer.xcodeproj/        # Xcode project file
├── PackageViewer/
│   ├── PackageViewerApp.swift      # App entry point
│   ├── Models/                     # Data models
│   │   ├── Package.swift           # Package entity
│   │   ├── PackageManager.swift    # Package manager enum
│   │   └── PackageRepository.swift # Repository protocol
│   ├── Views/                      # SwiftUI views
│   │   ├── ContentView.swift       # Main tab view
│   │   ├── PackageListView.swift   # Package list view
│   │   ├── PackageRowView.swift    # Package row component
│   │   ├── EmptyStateView.swift    # Empty state component
│   │   └── SearchBar.swift         # Search bar component
│   ├── ViewModels/                 # View models
│   │   └── PackageListViewModel.swift
│   ├── Services/                   # Business logic
│   │   ├── NpmPackageService.swift
│   │   ├── HomebrewPackageService.swift
│   │   ├── PipPackageService.swift
│   │   └── ShellCommandService.swift
│   └── Resources/                  # Assets, strings, etc.
│       ├── Assets.xcassets/
│       └── Localizable.strings
└── PackageViewerTests/
    ├── ModelTests/
    ├── ServiceTests/
    └── ViewTests/
```

**Structure Decision**: Single native macOS application using standard Xcode project structure. The app follows MVVM architecture pattern common in SwiftUI applications:
- **Models**: Data entities representing packages and package managers
- **Views**: SwiftUI view components for UI
- **ViewModels**: Bridge between models and views, handle business logic
- **Services**: Interact with external package managers via shell commands

This structure separates concerns, enables testing, and follows SwiftUI best practices.
