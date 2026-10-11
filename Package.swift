// swift-tools-version: 5.9
import PackageDescription

var targets: [Target] = [
    .target(name: "KeebsCore"),
    .executableTarget(
        name: "KeebsApp",
        dependencies: ["KeebsCore", .product(name: "Sparkle", package: "Sparkle", condition: .when(platforms: [.macOS]))],
        resources: [.copy("Resources")],
        linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"], .when(platforms: [.macOS]))]
    ),
    .testTarget(name: "KeebsCoreTests", dependencies: ["KeebsCore"])
]
#if os(macOS)
targets.append(.testTarget(name: "KeebsAppTests", dependencies: ["KeebsApp", "KeebsCore"]))
#endif

let package = Package(
    name: "Keebs",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Keebs", targets: ["KeebsApp"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle.git", exact: "2.10.0")],
    targets: targets
)
