import Foundation
import SwiftUI

class Package: ObservableObject, Identifiable, Equatable {
    let id: String
    let name: String
    let manager: PackageManager
    let description: String?
    let installationDate: Date?
    let version: String?
    let path: String?
    @Published var latestVersion: String?
    @Published var isCheckingUpdate: Bool = false
    @Published var isUpdating: Bool = false

    init(
        name: String,
        manager: PackageManager,
        description: String? = nil,
        installationDate: Date? = nil,
        version: String? = nil,
        path: String? = nil,
        latestVersion: String? = nil
    ) {
        self.name = name.trimmingCharacters(in: .whitespaces)
        self.manager = manager
        self.description = description
        self.installationDate = installationDate
        self.version = version
        self.path = path
        self.latestVersion = latestVersion
        self.id = "\(manager.rawValue)/\(self.name)"
    }

    static func == (lhs: Package, rhs: Package) -> Bool {
        lhs.id == rhs.id &&
        lhs.latestVersion == rhs.latestVersion &&
        lhs.isCheckingUpdate == rhs.isCheckingUpdate &&
        lhs.isUpdating == rhs.isUpdating
    }

    var hasUpdateAvailable: Bool {
        guard let current = version, let latest = latestVersion else { return false }
        return current != latest && !latest.isEmpty
    }
}
