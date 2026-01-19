// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PackageViewer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "PackageViewer",
            targets: ["PackageViewer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PackageViewer",
            dependencies: [],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        )
    ]
)
