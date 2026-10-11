// swift-tools-version: 5.9
import PackageDescription

var targets: [Target] = [
    .target(name: "KeebsCore"),
    .executableTarget(name: "KeebsApp", dependencies: ["KeebsCore"], resources: [.copy("Resources")]),
    .testTarget(name: "KeebsCoreTests", dependencies: ["KeebsCore"])
]
#if os(macOS)
targets.append(.testTarget(name: "KeebsAppTests", dependencies: ["KeebsApp", "KeebsCore"]))
#endif

let package = Package(
    name: "Keebs",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Keebs", targets: ["KeebsApp"])],
    targets: targets
)
