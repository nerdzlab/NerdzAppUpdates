// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NerdzAppUpdates",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NerdzAppUpdates",
            targets: ["NerdzAppUpdates"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "NerdzUtils", url: "https://github.com/nerdzlab/NerdzUtils.git", from: "1.0.68"),
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMajor(from: "8.3.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NerdzAppUpdates",
            dependencies: [
                .product(name: "FirebaseRemoteConfig", package: "Firebase"),
                .product(name: "NerdzUtils", package: "NerdzUtils")
            ]
        )
    ]
)
