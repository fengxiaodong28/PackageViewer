import Foundation
import SwiftUI

@MainActor
class PackageListViewModel: ObservableObject {
    @Published var packages: [Package] = []
    @Published var filteredPackages: [Package] = []
    @Published var searchQuery: String = "" {
        didSet {
            filterPackages()
        }
    }
    @Published var isLoading: Bool = false
    @Published var error: PackageError?
    @Published var isManagerInstalled: Bool = true
    @Published var hasLoadedOnce: Bool = false
    @Published var packageCount: Int = 0
    @Published var updateAlert: UpdateAlert?

    private let service: PackageRepository
    let manager: PackageManager

    struct UpdateAlert: Identifiable {
        let id = UUID()
        let packageName: String
        let success: Bool
        let error: String?
    }

    init(manager: PackageManager) {
        self.manager = manager
        switch manager {
        case .npm:
            self.service = NpmPackageService()
        case .homebrew:
            self.service = HomebrewPackageService()
        case .pip:
            self.service = PipPackageService()
        }
    }

    var isEmpty: Bool {
        packages.isEmpty
    }

    func loadPackages() async {
        // Only load if not already loaded to preserve state
        if hasLoadedOnce && !packages.isEmpty {
            return
        }

        isLoading = true
        self.error = nil

        let available = await service.isAvailable()
        if !available {
            self.isManagerInstalled = false
            self.error = .notInstalled
            isLoading = false
            return
        }

        do {
            let fetchedPackages = try await service.fetchPackages()
            packageCount = fetchedPackages.count

            // Sort in background to avoid blocking UI
            let sortedPackages = await Task.detached {
                fetchedPackages.sorted { $0.name.lowercased() < $1.name.lowercased() }
            }.value

            packages = sortedPackages
            filterPackages()  // Apply current search filter after reloading
            hasLoadedOnce = true
        } catch let commandError as CommandError {
            switch commandError {
            case .notFound:
                self.error = .notInstalled
                self.isManagerInstalled = false
            case .timeout:
                self.error = .timeout(10)
            case .failed(let code, let message):
                self.error = .commandFailed("Exit code \(code): \(message)")
            case .invalidOutput(let message):
                self.error = .parseFailed(message)
            }
        } catch let packageError as PackageError {
            self.error = packageError
        } catch {
            self.error = .unknown(error)
        }

        isLoading = false
    }

    func search(_ query: String) {
        searchQuery = query
    }

    func clearSearch() {
        searchQuery = ""
    }

    func retry() {
        self.error = nil
        hasLoadedOnce = false
        Task {
            await loadPackages()
        }
    }

    func refresh() {
        // Reset all package states
        for package in packages {
            package.latestVersion = nil
            package.isCheckingUpdate = false
            package.isUpdating = false
        }
        // Reload packages
        hasLoadedOnce = false
        Task {
            await loadPackages()
        }
    }

    func checkLatestVersion(for package: Package) async {
        package.isCheckingUpdate = true

        defer {
            package.isCheckingUpdate = false
        }

        do {
            let latestVersion = try await service.queryLatestVersion(for: package)
            package.latestVersion = latestVersion
        } catch {
            // Silently handle error - user can retry manually
            package.latestVersion = nil
        }
    }

    func updatePackage(_ package: Package) async {
        package.isUpdating = true

        defer {
            package.isUpdating = false
        }

        do {
            try await service.updatePackage(package)
            // Reload packages to get updated version
            hasLoadedOnce = false
            await loadPackages()

            // Show success alert
            updateAlert = UpdateAlert(
                packageName: package.name,
                success: true,
                error: nil
            )
        } catch let commandError as CommandError {
            switch commandError {
            case .notFound:
                self.error = .notInstalled
            case .timeout:
                self.error = .timeout(30)
            case .failed(let code, let message):
                self.error = .commandFailed("Exit code \(code): \(message)")
            case .invalidOutput(let message):
                self.error = .parseFailed(message)
            }
            // Show error alert
            updateAlert = UpdateAlert(
                packageName: package.name,
                success: false,
                error: commandError.localizedDescription
            )
        } catch let packageError as PackageError {
            self.error = packageError
            updateAlert = UpdateAlert(
                packageName: package.name,
                success: false,
                error: packageError.localizedDescription
            )
        } catch {
            self.error = .unknown(error)
            updateAlert = UpdateAlert(
                packageName: package.name,
                success: false,
                error: error.localizedDescription
            )
        }
    }

    private func filterPackages() {
        if searchQuery.isEmpty {
            filteredPackages = packages
        } else {
            filteredPackages = packages.filter { package in
                package.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        // Update package count to display filtered results
        packageCount = filteredPackages.count
    }
}
