// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PomodoroStar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "PomodoroStar", targets: ["PomodoroStar"]),
        .library(name: "PomodoroStarCore", targets: ["PomodoroStarCore"])
    ],
    targets: [
        .target(
            name: "PomodoroStarCore",
            path: "Sources/PomodoroStarCore"
        ),
        .executableTarget(
            name: "PomodoroStar",
            dependencies: ["PomodoroStarCore"],
            path: "Sources/PomodoroStar"
        ),
        .testTarget(
            name: "PomodoroStarCoreTests",
            dependencies: ["PomodoroStarCore"],
            path: "Tests/PomodoroStarCoreTests"
        )
    ]
)
