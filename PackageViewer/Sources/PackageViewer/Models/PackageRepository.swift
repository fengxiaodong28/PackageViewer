import Foundation

protocol PackageRepository {
    func fetchPackages() async throws -> [Package]
    func isAvailable() async -> Bool
    func queryLatestVersion(for package: Package) async throws -> String
    func updatePackage(_ package: Package) async throws
}

enum PackageError: LocalizedError {
    case notInstalled
    case timeout(TimeInterval)
    case commandFailed(String)
    case parseFailed(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Package manager is not installed on this system"
        case .timeout(let duration):
            return "Operation timed out after \(duration) seconds"
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .parseFailed(let message):
            return "Failed to parse package data: \(message)"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notInstalled:
            return "Please install the package manager to view its packages"
        case .timeout:
            return "Try again with fewer packages or check system performance"
        case .commandFailed:
            return "Check that the package manager is working correctly"
        case .parseFailed:
            return "Package data format may have changed"
        case .unknown:
            return "Please try again or contact support if the issue persists"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .notInstalled:
            return false
        case .timeout, .commandFailed, .parseFailed, .unknown:
            return true
        }
    }
}

enum CommandError: LocalizedError {
    case notFound(String)
    case timeout(String)
    case failed(Int, String)
    case invalidOutput(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let command):
            return "Command not found: \(command)"
        case .timeout(let command):
            return "Command timed out: \(command)"
        case .failed(let code, let message):
            return "Command failed with exit code \(code): \(message)"
        case .invalidOutput(let message):
            return "Invalid command output: \(message)"
        }
    }
}
