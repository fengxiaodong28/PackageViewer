import Foundation

struct Package: Identifiable, Equatable {
    let id: String
    let name: String
    let manager: PackageManager
    let description: String?
    let installationDate: Date?
    let version: String?
    let path: String?

    init(
        name: String,
        manager: PackageManager,
        description: String? = nil,
        installationDate: Date? = nil,
        version: String? = nil,
        path: String? = nil
    ) {
        self.name = name.trimmingCharacters(in: .whitespaces)
        self.manager = manager
        self.description = description
        self.installationDate = installationDate
        self.version = version
        self.path = path
        self.id = "\(manager.rawValue)/\(self.name)"
    }

    static func == (lhs: Package, rhs: Package) -> Bool {
        lhs.id == rhs.id
    }
}
