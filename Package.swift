// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MerchantKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v11), .macOS(.v10_14)],
    products: [
        .library(
            name: "MerchantKit",
            targets: ["MerchantKit"]),
    ],
    targets: [
        .target(
            name: "MerchantKit",
            dependencies: [],
            path: "Source",
            publicHeadersPath: "Source"),
    ]
)
