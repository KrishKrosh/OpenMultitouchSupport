// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "OpenMultitouchSupport",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "OpenMultitouchSupport",
            targets: ["OpenMultitouchSupport"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "OpenMultitouchSupportXCF",
            // For development: use local framework
            // path: "OpenMultitouchSupportXCF.xcframework"
            // For release: use GitHub URL (replaced by release script)
            url: "https://github.com/KrishKrosh/OpenMultitouchSupport/releases/download/v1.0.10/OpenMultitouchSupportXCF.xcframework.zip",
            checksum: "65d4a5b64e9c49b0482f3f42e495606cfa7649c0eb2d837373097bc70324e29d"
        ),
        .target(
            name: "OpenMultitouchSupport",
            dependencies: ["OpenMultitouchSupportXCF"],
            swiftSettings: swiftSettings
        )
    ]
) 