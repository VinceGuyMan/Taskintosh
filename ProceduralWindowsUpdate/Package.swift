// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProceduralWindowsUpdate",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ProceduralWindowsUpdate",
            targets: ["ProceduralWindowsUpdate"]
        ),
        .executable(
            name: "FakeUpdatePreview",
            targets: ["FakeUpdatePreview"]
        ),
        .executable(
            name: "ProceduralWindowsUpdateTestRunner",
            targets: ["ProceduralWindowsUpdateTestRunner"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProceduralWindowsUpdate",
            dependencies: [],
            path: "Sources/ProceduralWindowsUpdate"
        ),
        .executableTarget(
            name: "FakeUpdatePreview",
            dependencies: ["ProceduralWindowsUpdate"],
            path: "PreviewApp"
        ),
        .executableTarget(
            name: "ProceduralWindowsUpdateTestRunner",
            dependencies: ["ProceduralWindowsUpdate"],
            path: "Tests/TestRunner"
        ),
        .testTarget(
            name: "ProceduralWindowsUpdateTests",
            dependencies: ["ProceduralWindowsUpdate"],
            path: "Tests/ProceduralWindowsUpdateTests"
        )
    ]
)
