// swift-tools-version:5.3

import PackageDescription


let package = Package(
    name: "swift-nio-ip",
    products: [
        .library(name: "NIOIP", targets: ["NIOIP"])
    ],
    dependencies: [
        .package(name: "swift-nio", url: "https://github.com/apple/swift-nio.git", from: "2.25.1")
    ],
    targets: [
        .target(
            name: "NIOIP",
            dependencies: [
                .product(name: "NIO", package: "swift-nio")
            ]
        ),
        .testTarget(
            name: "NIOIPTests",
            dependencies: [
                .target(name: "NIOIP")
            ]
        )
    ]
)
