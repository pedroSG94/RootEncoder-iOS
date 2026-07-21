// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RootEncoder",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "RootEncoder", targets: ["RootEncoder"]),
    ],
    targets: [
        .target(name: "Common", path: "RootEncoder/Sources/RootEncoder/common"),
        .target(name: "Encoder", dependencies: ["Common"],
                path: "RootEncoder/Sources/RootEncoder/encoder",
                resources: [.copy("input/metal/shaders")]),
        .target(name: "RTMP", dependencies: ["Common"],
                path: "RootEncoder/Sources/RootEncoder/rtmp"),
        .target(name: "RTSP", dependencies: ["Common"],
                path: "RootEncoder/Sources/RootEncoder/rtsp"),
        .target(name: "SRT", dependencies: ["Common"],
                path: "RootEncoder/Sources/RootEncoder/srt"),
        .target(name: "RootEncoder",
                dependencies: ["Common", "Encoder", "RTMP", "RTSP", "SRT"],
                path: "RootEncoder/Sources/RootEncoder/library"),
        .testTarget(name: "RootEncoderTests", dependencies: ["RootEncoder"],
                path: "RootEncoder/Tests/RootEncoderTests"),
    ]
)
