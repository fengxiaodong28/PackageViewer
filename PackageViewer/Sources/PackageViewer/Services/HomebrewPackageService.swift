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
}
