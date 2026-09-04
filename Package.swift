// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Taskintosh",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Taskintosh", targets: ["Taskintosh"]),
        .library(name: "TaskintoshKit", targets: ["TaskintoshKit"]),
        .library(name: "ProceduralWindowsUpdate", targets: ["ProceduralWindowsUpdate"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProceduralWindowsUpdate",
            dependencies: [],
            path: "ProceduralWindowsUpdate/Sources/ProceduralWindowsUpdate"
        ),
        .target(
            name: "TaskintoshKit",
            dependencies: [],
            path: "Sources/TaskintoshKit",
            resources: [
                .copy("Resources/Eras"),
                .copy("Resources/Brand")
            ]
        ),
        .executableTarget(
            name: "Taskintosh",
            dependencies: ["TaskintoshKit", "ProceduralWindowsUpdate"],
            path: "Sources/Taskintosh",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TaskintoshTests",
            dependencies: ["TaskintoshKit", "ProceduralWindowsUpdate"],
            path: "Tests/TaskintoshTests"
        )
    ]
)
