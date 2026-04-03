// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "fanctl",
    platforms: [.macOS(.v14)],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "fanctl",
            dependencies: ["SMCKit"],
            path: "Sources/fanctl"
        ),
        .target(
            name: "SMCKit",
            path: "Sources/SMCKit",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
    ]
)
