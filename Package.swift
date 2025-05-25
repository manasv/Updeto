// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Updeto",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Updeto",
            targets: ["Updeto"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Updeto",
            dependencies: []),
        .testTarget(
            name: "UpdetoTests",
            dependencies: ["Updeto"]),
    ]
)