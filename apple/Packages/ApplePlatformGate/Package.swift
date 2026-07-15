// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ApplePlatformGate",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "G3AppProbe", targets: ["G3AppProbe"]),
        .library(name: "G3WidgetActivityProbe", targets: ["G3WidgetActivityProbe"]),
        .library(name: "G3WatchProbe", targets: ["G3WatchProbe"])
    ],
    dependencies: [
        .package(path: "../SalaryCore")
    ],
    targets: [
        .target(
            name: "G3AppProbe",
            dependencies: [.product(name: "SalaryCore", package: "SalaryCore")]
        ),
        .target(
            name: "G3WidgetActivityProbe",
            dependencies: [.product(name: "SalaryCore", package: "SalaryCore")]
        ),
        .target(
            name: "G3WatchProbe",
            dependencies: [.product(name: "SalaryCore", package: "SalaryCore")]
        )
    ]
)
