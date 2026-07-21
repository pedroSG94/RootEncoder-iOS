// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RootEncoder",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "RootEncoder", targets: ["RootEncoder"]),
    ],
    targets: [
        .target(name: "common", path: "common"),
        .target(name: "encoder", dependencies: ["common"],
                path: "encoder",
                resources: [.copy("input/metal/shaders")]),
        .target(name: "rtmp", dependencies: ["common"], path: "rtmp"),
        .target(name: "rtsp", dependencies: ["common"], path: "rtsp"),
        .target(name: "srt", dependencies: ["common"], path: "srt"),
        .target(name: "RootEncoder",
                dependencies: ["common", "encoder", "rtmp", "rtsp", "srt"],
                path: "library"),
        .testTarget(name: "RootEncoderTests", dependencies: ["RootEncoder"],
                path: "RootEncoderTests"),
    ]
)
