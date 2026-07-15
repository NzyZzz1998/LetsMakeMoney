// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SalaryCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "SalaryCore", targets: ["SalaryCore"])
    ],
    targets: [
        .target(name: "SalaryCore"),
        .testTarget(name: "SalaryCoreTests", dependencies: ["SalaryCore"])
    ]
)
