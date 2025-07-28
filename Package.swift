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
            url: "https://github.com/KrishKrosh/OpenMultitouchSupport/releases/download/v1.0.11/OpenMultitouchSupportXCF.xcframework.zip",
            checksum: "12e302ec4c08a24c5a78be3ff67417191f0f010165325325553116837d2e7505"
        ),
        .target(
            name: "OpenMultitouchSupport",
            dependencies: ["OpenMultitouchSupportXCF"],
            swiftSettings: swiftSettings
        )
    ]
) 