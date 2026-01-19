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

    private let service: PackageRepository
    let manager: PackageManager

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
            filteredPackages = sortedPackages
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
