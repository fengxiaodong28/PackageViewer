import Foundation

enum PackageManager: String, CaseIterable, Identifiable {
    case npm = "npm"
    case homebrew = "homebrew"
    case pip = "pip"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .npm: return "npm"
        case .homebrew: return "Homebrew"
        case .pip: return "pip"
        }
    }

    var iconName: String {
        switch self {
        case .npm: return "cube.box.fill"
        case .homebrew: return "mug.fill"
        case .pip: return "circle.fill"
        }
    }

    var command: String {
        switch self {
        case .npm: return "npm"
        case .homebrew: return "brew"
        case .pip: return "pip3"
        }
    }
}
