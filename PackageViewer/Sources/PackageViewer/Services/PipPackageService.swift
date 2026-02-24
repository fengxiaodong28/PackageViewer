import Foundation

class PipPackageService: PackageRepository {
    private let shellService = ShellCommandService()

    func fetchPackages() async throws -> [Package] {
        let output = try await shellService.execute(command: "pip3", arguments: ["list", "--format=json"])

        guard let data = output.data(using: .utf8) else {
            throw PackageError.parseFailed("Invalid pip output format")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw PackageError.parseFailed("Invalid pip output format")
        }

        // Get site-packages path
        let sitePath: String
        do {
            let siteOutput = try await shellService.execute(command: "python3", arguments: ["-m", "site"])
            let paths = siteOutput.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("sys.path") && !$0.hasPrefix("[") && !$0.hasPrefix("]") }
                .compactMap { line in
                    var path = line.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "\"", with: "")
                    path = path.replacingOccurrences(of: ",", with: "")
                    return path.hasPrefix("/") && (path.contains("site-packages") || path.contains("dist-packages")) ? path : nil
                }
            sitePath = paths.first ?? "/opt/anaconda3/lib/python3.13/site-packages"
        } catch {
            sitePath = "/opt/anaconda3/lib/python3.13/site-packages"
        }

        var packages: [Package] = []

        // Collect package info efficiently
        for packageInfo in json {
            guard let name = packageInfo["name"] as? String else { continue }
            let version = packageInfo["version"] as? String

            let dirName = name.replacingOccurrences(of: "-", with: "_")
            let packagePath = "\(sitePath)/\(dirName)"

            packages.append(Package(
                name: name,
                manager: .pip,
                version: version,
                path: packagePath
            ))
        }

        return packages
    }

    func isAvailable() async -> Bool {
        do {
            _ = try await shellService.execute(command: "pip3", arguments: ["--version"])
            return true
        } catch {
            return false
        }
    }

    func queryLatestVersion(for package: Package) async throws -> String {
        // Use pip index versions command - simple and reliable
        let output = try await shellService.execute(
            command: "pip3",
            arguments: ["index", "versions", package.name],
            timeout: 15.0
        )

        // Parse the output to find LATEST version
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("  LATEST:") {
                let version = line.replacingOccurrences(of: "  LATEST:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !version.isEmpty {
                    return version
                }
            }
        }

        throw PackageError.parseFailed("Could not find latest version in pip index output")
    }

    func updatePackage(_ package: Package) async throws {
        // Use 180 seconds timeout for pip install which may need to download and compile packages
        _ = try await shellService.execute(command: "pip3", arguments: ["install", "--upgrade", package.name], timeout: 180.0)
    }
}
