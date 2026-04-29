// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OneStepCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "OneStepCore", targets: ["OneStepCore"])
    ],
    targets: [
        .target(name: "OneStepCore"),
        .testTarget(name: "OneStepCoreTests", dependencies: ["OneStepCore"])
    ]
)
