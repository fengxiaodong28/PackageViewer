import Foundation

class NpmPackageService: PackageRepository {
    private let shellService = ShellCommandService()

    func fetchPackages() async throws -> [Package] {
        let listOutput = try await shellService.execute(command: "npm", arguments: ["list", "-g", "--depth=0", "--json"])

        guard let data = listOutput.data(using: .utf8) else {
            throw PackageError.parseFailed("Could not decode npm output")
        }

        let npmPrefix: String
        do {
            let prefixOutput = try await shellService.execute(command: "npm", arguments: ["prefix", "-g"])
            npmPrefix = prefixOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            npmPrefix = "/usr/local"
        }

        let nodeModulesPath = "\(npmPrefix)/lib/node_modules"

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let dependencies = json?["dependencies"] as? [String: [String: Any]] ?? [:]

            var packages: [Package] = []

            // Collect package info efficiently
            for (name, info) in dependencies {
                let version = info["version"] as? String
                let packagePath = "\(nodeModulesPath)/\(name)"

                packages.append(Package(
                    name: name,
                    manager: .npm,
                    version: version,
                    path: packagePath
                ))
            }

            return packages
        } catch let error as PackageError {
            throw error
        } catch {
            throw PackageError.parseFailed("Invalid npm output format: \(error.localizedDescription)")
        }
    }

    func isAvailable() async -> Bool {
        do {
            _ = try await shellService.execute(command: "npm", arguments: ["--version"])
            return true
        } catch {
            return false
        }
    }

    func queryLatestVersion(for package: Package) async throws -> String {
        let output = try await shellService.execute(command: "npm", arguments: ["view", package.name, "version"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func updatePackage(_ package: Package) async throws {
        // Use 600 seconds (10 minutes) timeout for npm install which may need to download and compile packages
        _ = try await shellService.execute(command: "npm", arguments: ["install", "-g", "\(package.name)@latest"], timeout: 600.0)
    }
}
