// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MerchantKit",
    platforms: [.iOS(.v11), .macOS(.v10_14)],
    products: [
        .library(name: "MerchantKit", targets: ["MerchantKit"])
    ],
    targets: [
        .target(name: "MerchantKit", path: "Source"),
        .testTarget(name: "MerchantKitTests", dependencies: ["MerchantKit"], path: "Tests")
    ]
)
