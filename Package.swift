// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Budgeting",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Budgeting",
            targets: ["Budgeting"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Budgeting"),
        .testTarget(
            name: "BudgetingTests",
            dependencies: [
                "Budgeting",
            ]
        ),
    ]
)
