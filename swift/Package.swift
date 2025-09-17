// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VortexWars3",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VortexWars3",
            type: .dynamic,
            targets: ["VortexWars3"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VortexWars3",
            dependencies: [
                .product(name: "SwiftGodot", package: "swiftgodot")
            ],
            plugins: [                
                .plugin(name: "EntryPointGeneratorPlugin", package: "swiftgodot")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
