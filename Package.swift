// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HomeMaint",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "HomeMaint",
            targets: ["HomeMaint"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HomeMaint",
            dependencies: [],
            path: "HomeMaint",
            exclude: ["Resources"]
        )
    ]
)
