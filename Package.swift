// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Keebs",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Keebs", targets: ["KeebsApp"])],
    targets: [
        .target(name: "KeebsCore"),
        .executableTarget(name: "KeebsApp", dependencies: ["KeebsCore"], resources: [.copy("Resources")]),
        .testTarget(name: "KeebsCoreTests", dependencies: ["KeebsCore"])
    ]
)
