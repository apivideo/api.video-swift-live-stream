// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ApiVideoLiveStream",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_12),
        .tvOS(.v10)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ApiVideoLiveStream",
            targets: ["ApiVideoLiveStream"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/shogo4405/HaishinKit.swift", from: "1.2.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ApiVideoLiveStream",
            dependencies: [.product(name: "HaishinKit", package: "HaishinKit.swift"), ],
            path: "Sources"
        ),
        // Targets for tests
        .testTarget(
            name: "ApiVideoLiveStreamTests",
            dependencies: ["ApiVideoLiveStream"],
            path: "Tests"
        ),
    ]
)
