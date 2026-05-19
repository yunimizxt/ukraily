// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Ukraily",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "UkrailyCore", targets: ["UkrailyCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "UkrailyCore",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "Sources/UkrailyCore",
            resources: [
                .process("Utilities/Stations.json"),
            ]
        ),
        .target(
            name: "UkrailyApp",
            dependencies: ["UkrailyCore"],
            path: "Sources/UkrailyApp"
        ),
        .target(
            name: "UkrailyWidgets",
            dependencies: ["UkrailyCore"],
            path: "Sources/UkrailyWidgets"
        ),
        .target(
            name: "UkrailyWatch",
            dependencies: ["UkrailyCore"],
            path: "Sources/UkrailyWatch"
        ),
        .testTarget(
            name: "UkrailyCoreTests",
            dependencies: ["UkrailyCore"],
            path: "Tests/UkrailyCoreTests",
            resources: [
                .process("Fixtures"),
            ]
        ),
    ]
)
