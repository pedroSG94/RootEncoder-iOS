// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RootEncoder",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RootEncoder",
            targets: ["RootEncoder"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RootEncoder",
            path: "RootEncoder/Sources/RootEncoder",
            resources: [
                //shader files are read as strings at runtime and compiled with device.makeLibrary,
                //declared as resources to avoid the offline Metal compiler (no Metal Toolchain needed)
                .copy("encoder/input/metal/shaders"),
            ]
        ),
        .testTarget(
            name: "RootEncoderTests",
            dependencies: ["RootEncoder"],
            path: "RootEncoder/Tests/RootEncoderTests"
        ),
    ]
)
