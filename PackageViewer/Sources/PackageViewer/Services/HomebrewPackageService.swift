import Foundation

class HomebrewPackageService: PackageRepository {
    private let shellService = ShellCommandService()

    func fetchPackages() async throws -> [Package] {
        let output = try await shellService.execute(command: "brew", arguments: ["list", "--formula"])

        let packageNames = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var packages: [Package] = []

        // Determine Homebrew prefix
        let prefix: String
        do {
            let prefixOutput = try await shellService.execute(command: "brew", arguments: ["--prefix"])
            prefix = prefixOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            prefix = "/usr/local"
        }

        let cellarPath = "\(prefix)/Cellar"

        // Collect package info efficiently
        for name in packageNames {
            let packagePath = "\(cellarPath)/\(name)"

            var version: String? = nil
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: packagePath),
               let versions = try? fileManager.contentsOfDirectory(atPath: packagePath) {
                // Sort versions to get the actual latest
                let sortedVersions = versions.sorted(by: { $0.compare($1, options: .numeric) == .orderedAscending })
                version = sortedVersions.last
            }

            packages.append(Package(
                name: name,
                manager: .homebrew,
                version: version,
                path: packagePath
            ))
        }

        return packages
    }

    func isAvailable() async -> Bool {
        do {
            _ = try await shellService.execute(command: "brew", arguments: ["--version"])
            return true
        } catch {
            return false
        }
    }

    func queryLatestVersion(for package: Package) async throws -> String {
        let output = try await shellService.execute(command: "brew", arguments: ["info", "--json=v2", package.name])
        guard let data = output.data(using: .utf8) else {
            throw PackageError.parseFailed("Could not decode brew info output")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let formulae = json["formulae"] as? [[String: Any]],
              let formula = formulae.first,
              let versions = formula["versions"] as? [String: Any],
              let stable = versions["stable"] as? String else {
            throw PackageError.parseFailed("Could not parse version from brew info output")
        }
        return stable
    }

    func updatePackage(_ package: Package) async throws {
        // Use 180 seconds timeout for brew upgrade which may need to download and compile packages
        // First try upgrading as a formula
        do {
            _ = try await shellService.execute(command: "brew", arguments: ["upgrade", package.name], timeout: 180.0)
        } catch {
            // If formula upgrade fails, try as cask
            let output = try await shellService.execute(command: "brew", arguments: ["list", "--cask"])
            let casks = output.components(separatedBy: .newlines).filter { !$0.isEmpty }

            if casks.contains(package.name) {
                _ = try await shellService.execute(command: "brew", arguments: ["upgrade", "--cask", package.name], timeout: 180.0)
            } else {
                throw error
            }
        }
    }
}
