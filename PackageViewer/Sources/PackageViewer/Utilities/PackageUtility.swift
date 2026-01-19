import Foundation

/// Shared utility functions for package operations
enum PackageUtility {
    /// Formats bytes into human-readable string (B, KB, MB, GB)
    static func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024

        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.0f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }

    /// Calculates the total size of a directory recursively
    /// - Parameter path: The directory path to calculate size for
    /// - Returns: Formatted size string, or "-" if path doesn't exist/empty
    static func calculateDirectorySize(path: String) -> String {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        guard fileManager.fileExists(atPath: path) else {
            return "-"
        }

        func accumulateSize(at url: URL) {
            guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
                return
            }

            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                      let fileSize = resourceValues.fileSize else {
                    continue
                }
                totalSize += Int64(fileSize)
            }
        }

        accumulateSize(at: URL(fileURLWithPath: path))

        if totalSize == 0 {
            return "-"
        }

        return formatBytes(totalSize)
    }

    /// Gets the modification date of a file/directory
    /// - Parameter path: The path to check
    /// - Returns: Modification date, or nil if unable to retrieve
    static func getModificationDate(path: String) -> Date? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}
