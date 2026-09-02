// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Taskintosh",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Taskintosh", targets: ["Taskintosh"]),
        .library(name: "TaskintoshKit", targets: ["TaskintoshKit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TaskintoshKit",
            dependencies: [],
            path: "Sources/TaskintoshKit",
            resources: [
                .copy("Resources/Eras")
            ]
        ),
        .executableTarget(
            name: "Taskintosh",
            dependencies: ["TaskintoshKit"],
            path: "Sources/Taskintosh"
        ),
        .testTarget(
            name: "TaskintoshTests",
            dependencies: ["TaskintoshKit"],
            path: "Tests/TaskintoshTests"
        )
    ]
)
