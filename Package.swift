// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MerchantKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v12), .macOS(.v10_14)],
    products: [
        .library(name: "MerchantKit", targets: ["MerchantKit"]),
    ],
    targets: [
        .target(name: "MerchantKit", path: "Source", resources: [.process("Internal/Resources/")]),
        .testTarget(name: "MerchantKitTests", dependencies: ["MerchantKit"], path: "Tests", exclude: ["Info.plist"], resources: [.process("Sample Resources")])
    ]
)
