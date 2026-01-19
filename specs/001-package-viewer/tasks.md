# Tasks: macOS Package Viewer

**Input**: Design documents from `/specs/001-package-viewer/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/internal-api.md

**Tests**: No tests explicitly requested in feature specification. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **macOS app**: `PackageViewer/` at repository root
- **Tests**: `PackageViewerTests/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Xcode project structure

- [X] T001 Create PackageViewer directory structure at repository root per implementation plan (Models/, Views/, ViewModels/, Services/, Resources/)
- [X] T002 Create new Xcode project: macOS App, SwiftUI interface, Swift language, named "PackageViewer" in PackageViewer/ directory
- [X] T003 [P] Set deployment target to macOS 14.0 in Xcode project settings
- [X] T004 [P] Create Assets.xcassets in PackageViewer/Resources/ for app assets
- [X] T005 [P] Create Localizable.strings in PackageViewer/Resources/ for localized strings
- [X] T006 [P] Create test directory structure: PackageViewerTests/ModelTests/, ServiceTests/, ViewTests/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models and shell command infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Core Data Models

- [X] T007 Create Package struct in PackageViewer/Models/Package.swift with fields: id, name, manager, size, description, installationDate, version, path (per data-model.md)
- [X] T008 Create PackageManager enum in PackageViewer/Models/PackageManager.swift with cases: npm, homebrew, pip (per data-model.md)
- [X] T009 Create PackageRepository protocol in PackageViewer/Models/PackageRepository.swift with fetchPackages() and isAvailable() methods (per contracts/internal-api.md)
- [X] T010 Create PackageError enum in PackageViewer/Models/PackageRepository.swift with cases: notInstalled, timeout, commandFailed, parseFailed, unknown (per data-model.md)

### Shell Command Infrastructure

- [X] T011 Create ShellCommandService in PackageViewer/Services/ShellCommandService.swift with execute() method using Process/Pipe (per contracts/internal-api.md)
- [X] T012 Create CommandError enum in PackageViewer/Services/ShellCommandService.swift with cases: notFound, timeout, failed, invalidOutput (per contracts/internal-api.md)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Installed Packages (Priority: P1) 🎯 MVP

**Goal**: Display list of installed packages from npm, Homebrew, or pip with name, size, description, and installation date

**Independent Test**: Launch app, select package type (e.g., npm), verify packages display with all required fields (name, size, description, date). Test with empty package list to verify empty state.

### Package Services (one per manager)

- [X] T013 [P] [US1] Create NpmPackageService in PackageViewer/Services/NpmPackageService.swift implementing PackageRepository, parsing npm list output (per contracts/internal-api.md)
- [X] T014 [P] [US1] Create HomebrewPackageService in PackageViewer/Services/HomebrewPackageService.swift implementing PackageRepository, parsing brew info output (per contracts/internal-api.md)
- [X] T015 [P] [US1] Create PipPackageService in PackageViewer/Services/PipPackageService.swift implementing PackageRepository, parsing pip list output (per contracts/internal-api.md)

### View Model

- [X] T016 [US1] Create PackageListViewModel in PackageViewer/ViewModels/PackageListViewModel.swift with @Published properties: packages, filteredPackages, searchQuery, isLoading, error (per data-model.md)
- [X] T017 [US1] Implement loadPackages() async method in PackageListViewModel that calls service.fetchPackages() and updates state (per data-model.md)
- [X] T018 [US1] Implement error handling in PackageListViewModel.loadPackages() mapping service errors to PackageError (per contracts/internal-api.md)

### Views - Display Components

- [X] T019 [P] [US1] Create PackageRowView in PackageViewer/Views/PackageRowView.swift displaying package name, size, description, installation date (per contracts/internal-api.md)
- [X] T020 [P] [US1] Create EmptyStateView in PackageViewer/Views/EmptyStateView.swift with message and icon parameters (per contracts/internal-api.md)
- [X] T021 [US1] Create PackageListView in PackageViewer/Views/PackageListView.swift with loading/error/empty/list states, displaying filteredPackages via PackageRowView (per contracts/internal-api.md)

### Views - Container & Navigation

- [X] T022 [US1] Create ContentView in PackageViewer/Views/ContentView.swift with TabView containing 3 PackageListView instances (one per PackageManager) (per contracts/internal-api.md)
- [X] T023 [US1] Update PackageViewerApp.swift to set ContentView as root view using WindowGroup

**Checkpoint**: At this point, User Story 1 should be fully functional - user can launch app, switch tabs, and view packages from any installed package manager

---

## Phase 4: User Story 2 - Search and Filter Packages (Priority: P2)

**Goal**: Enable users to search for packages by name with real-time filtering

**Independent Test**: Launch app with 50+ packages, type search term (e.g., "react"), verify only matching packages display. Clear search and verify all packages return.

### Search Functionality

- [X] T024 [US2] Implement search(_:) method in PackageListViewModel filtering packages by name (case-insensitive) per data-model.md
- [X] T025 [US2] Implement clearSearch() method in PackageListViewModel resetting filteredPackages to all packages per data-model.md
- [X] T026 [US2] Update filteredPackages computed property in PackageListViewModel to react to searchQuery changes per data-model.md

### Search UI

- [X] T027 [US2] Create SearchBar in PackageViewer/Views/SearchBar.swift with text binding to viewModel.searchQuery (per contracts/internal-api.md)
- [X] T028 [US2] Add SearchBar to PackageListView above the List per contracts/internal-api.md
- [X] T029 [US2] Implement 300ms debounce in SearchBar using Combine or async delay per research.md performance optimizations
- [X] T030 [US2] Add "no results found" empty state in PackageListView when filteredPackages.isEmpty but searchQuery.isNotEmpty per FR-010

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - user can view packages and search/filter them in real-time

---

## Phase 5: User Story 3 - Navigate Between Package Types (Priority: P3)

**Goal**: Enable seamless tab switching between npm, Homebrew, and pip with search state management

**Independent Test**: Launch app, switch between all 3 tabs, verify correct packages load each time. Test search state clears when switching tabs per acceptance scenarios.

### Tab Switching Enhancement

- [X] T031 [US3] Add .id() modifier to PackageListView in ContentView with PackageManager as identifier per SwiftUI best practices
- [X] T032 [US3] Implement onAppear handler in PackageListView calling loadPackages() when tab becomes visible per contracts/internal-api.md
- [X] T033 [US3] Clear searchQuery in PackageListView.onAppear to reset search state when switching tabs per spec.md acceptance scenario 4

### Package Manager Detection

- [X] T034 [US3] Implement isAvailable() check in each package service (NpmPackageService, HomebrewPackageService, PipPackageService) per contracts/internal-api.md
- [X] T035 [US3] Add "not installed" error state in PackageListView when service.isAvailable() returns false per FR-015
- [X] T036 [US3] Display appropriate empty state message when package manager is not installed (e.g., "npm is not installed on this system") per FR-015

**Checkpoint**: All user stories should now be independently functional - user can view, search, and navigate between package types seamlessly

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Performance optimizations, edge case handling, and UX refinements

### Performance Optimizations

- [X] T037 [P] Implement background processing for size calculations using DispatchQueue.global() in package services per research.md
- [X] T038 [P] Add in-memory caching to PackageListViewModel to cache loaded packages per session per research.md
- [X] T039 Add progressive loading: display package names immediately, load metadata (size, description, date) in background per research.md

### Edge Case Handling

- [X] T040 [P] Handle missing metadata in PackageRowView: display "N/A" for optional fields when nil per data-model.md
- [X] T041 [P] Add timeout handling in ShellCommandService.execute() with 10-second timeout per contracts/internal-api.md
- [X] T042 [P] Handle large package lists (1000+) with lazy loading optimization in PackageListView List per research.md
- [X] T043 [P] Handle special characters and non-ASCII characters in package names per spec.md edge cases

### Error Handling & UX

- [X] T044 [P] Implement retry() method in PackageListViewModel clearing error and calling loadPackages() again per data-model.md
- [X] T045 Add retry button to error state in PackageListView per contracts/internal-api.md
- [X] T046 [P] Add user-friendly error messages for all PackageError cases with localized descriptions per contracts/internal-api.md
- [X] T047 [P] Ensure loading indicators display for operations taking > 200ms per constitution principle III

### Final Polish

- [X] T048 [P] Verify all user-facing strings are externalized to Localizable.strings per plan.md
- [X] T049 [P] Add accessibility labels to all interactive views per constitution principle III
- [X] T050 Run quickstart.md validation and verify app builds and runs per specs/001-package-viewer/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion - Can start immediately after Phase 2
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (extends PackageListViewModel and PackageListView)
- **User Story 3 (Phase 5)**: Depends on User Story 1 and 2 completion (enhances existing navigation and search)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - foundational story
- **User Story 2 (P2)**: Extends US1 by adding search to existing PackageListViewModel and PackageListView - cannot work independently
- **User Story 3 (P3)**: Enhances US1 and US2 by improving tab switching and package manager detection - cannot work independently

**NOTE**: Unlike typical web apps, this macOS app has tighter coupling between stories due to shared ViewModel and Views. US2 and US3 enhance US1 rather than providing standalone features.

### Within Each User Story

#### User Story 1 (View Installed Packages)
- T013, T014, T015 (services) can run in parallel [P]
- T019, T020 (view components) can run in parallel [P]
- T016 (viewModel) must precede T017, T018 (viewModel methods)
- T021 (PackageListView) depends on T016-T020
- T022, T023 (container views) must come last

#### User Story 2 (Search and Filter)
- T024-T026 (viewModel search methods) have sequential dependencies
- T027 (SearchBar) can start in parallel with T024-T026 [P]
- T028-T030 must follow T024-T027

#### User Story 3 (Navigation)
- T031-T033 (tab switching) can run in parallel with T034-T036 (package manager detection) [P]

### Parallel Opportunities

- **Setup phase**: T003, T004, T005, T006 can all run in parallel [P]
- **Foundational phase**: T007, T008, T009, T010 (data models) can run in parallel [P]; T011, T012 (shell services) sequential after models
- **User Story 1**: T013, T014, T015 (all package services) can run in parallel [P]; T019, T020 (view components) can run in parallel [P]
- **User Story 2**: T027 (SearchBar view) can run in parallel with T024-T026 (viewModel methods) [P]
- **User Story 3**: T031-T033 (tab switching) can run in parallel with T034-T036 (detection) [P]
- **Polish phase**: T037-T046 can mostly run in parallel [P]; T039, T045, T047 have dependencies

---

## Parallel Examples

### Example 1: User Story 1 Services (After Foundational Complete)

```bash
# Launch all three package services in parallel:
Task T013: "Create NpmPackageService in PackageViewer/Services/NpmPackageService.swift"
Task T014: "Create HomebrewPackageService in PackageViewer/Services/HomebrewPackageService.swift"
Task T015: "Create PipPackageService in PackageViewer/Services/PipPackageService.swift"
```

### Example 2: User Story 1 View Components (After ViewModel)

```bash
# Launch view components in parallel:
Task T019: "Create PackageRowView in PackageViewer/Views/PackageRowView.swift"
Task T020: "Create EmptyStateView in PackageViewer/Views/EmptyStateView.swift"
```

### Example 3: Polish Phase (After All Stories Complete)

```bash
# Launch polish tasks in parallel:
Task T037: "Implement background processing for size calculations"
Task T038: "Add in-memory caching to PackageListViewModel"
Task T040: "Handle missing metadata in PackageRowView"
Task T041: "Add timeout handling in ShellCommandService"
Task T042: "Handle large package lists with lazy loading"
Task T043: "Handle special characters in package names"
Task T044: "Implement retry method in PackageListViewModel"
Task T046: "Add user-friendly error messages"
Task T048: "Externalize strings to Localizable.strings"
Task T049: "Add accessibility labels to views"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only) - RECOMMENDED

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T012) - CRITICAL
3. Complete Phase 3: User Story 1 (T013-T023)
4. **STOP and VALIDATE**: Launch app, view packages from at least one manager
5. Demo MVP with full package viewing capability

**MVP delivers**: Users can view installed packages from npm, Homebrew, or pip with all required information (name, size, description, date). Empty states work.

### Incremental Delivery

1. MVP (Phase 1-3) → Deploy/Demo - Core package viewing
2. Add User Story 2 (Phase 4) → Deploy/Demo - Search functionality added
3. Add User Story 3 (Phase 5) → Deploy/Demo - Enhanced navigation and detection
4. Polish (Phase 6) → Deploy/Demo - Performance optimizations and edge cases

Each phase adds value without breaking previous functionality.

### Parallel Team Strategy (Multiple Developers)

With 2-3 developers after Foundational phase completes:

**Option A: Story-based (recommended)**
- Developer A: User Story 1 full implementation (T013-T023)
- Developer B: User Story 2 preparation (research search patterns, prepare for T024-T030)
- Developer C: User Story 3 preparation (research tab switching patterns, prepare for T031-T036)

**Option B: Layer-based**
- All developers complete Foundational together
- Developer A: All services (T013-T015, T034-T036)
- Developer B: All view models (T016-T018, T024-T026)
- Developer C: All views (T019-T023, T027-T030, T031-T033)

---

## Task Summary

- **Total Tasks**: 50
- **Setup (Phase 1)**: 6 tasks
- **Foundational (Phase 2)**: 6 tasks
- **User Story 1 (Phase 3)**: 11 tasks
- **User Story 2 (Phase 4)**: 7 tasks
- **User Story 3 (Phase 5)**: 6 tasks
- **Polish (Phase 6)**: 14 tasks

**Parallelizable Tasks**: 20 tasks marked with [P]

**Critical Path**: T001-T012 (Setup + Foundational) → T013-T023 (User Story 1)

**MVP Scope**: Phases 1-3 (23 tasks) delivers core package viewing capability

---

## Notes

- [P] tasks = different files or independent work, can run in parallel
- [US1], [US2], [US3] labels map tasks to user stories for traceability
- User Stories 2 and 3 enhance US1 rather than providing standalone features
- Tests omitted as not explicitly requested in specification
- Commit after each task or logical group (e.g., all services together)
- Stop at any checkpoint to validate story independently
- Performance optimizations (T037-T039) critical for 500+ package requirement (SC-004)
- All user-facing strings must be externalized (T048) per project standards
